module Input
  {% if flag?(:windows) %}
    private def self.empty_input_record : Windows::InputRecord
      Windows::InputRecord.new(
        event_type: 0_u16,
        event: StaticArray(UInt8, 16).new(0_u8)
      )
    end

    def self.read_n_console_inputs(console : Windows::Handle, max_events : UInt32) : Array(Windows::InputRecord)
      raise ArgumentError.new("max_events cannot be zero") if max_events == 0
      records = Array(Windows::InputRecord).new(max_events.to_i) { empty_input_record }
      n = Windows.read_console_input(console, Slice.new(records.to_unsafe, records.size))
      records[0, n.to_i]
    end

    def self.peek_n_console_inputs(console : Windows::Handle, max_events : UInt32) : Array(Windows::InputRecord)
      raise ArgumentError.new("max_events cannot be zero") if max_events == 0
      records = Array(Windows::InputRecord).new(max_events.to_i) { empty_input_record }
      n = Windows.peek_console_input(console, Slice.new(records.to_unsafe, records.size))
      records[0, n.to_i]
    end

    class Reader
      private def handle_con_input(con_reader : ConInputReader) : Array(Event)
        events = [] of Windows::InputRecord
        loop do
          events = Input.peek_n_console_inputs(con_reader.conin, 256_u32)
          raise CancelReader::ErrCanceled if con_reader.canceled?
          break if events.size > 0
          sleep 0.01
        end

        events = Input.read_n_console_inputs(con_reader.conin, events.size.to_u32)
        raise CancelReader::ErrCanceled if con_reader.canceled?

        evs = [] of Event
        events.each do |event|
          next unless e = @parser.not_nil!.parse_con_input_event(event, @key_state)
          if multi = e.as?(MultiEvent)
            evs.concat(multi.events)
          else
            evs << e
          end
        end
        evs
      end
    end

    class Parser
      def parse_con_input_event(event : Windows::InputRecord, key_state : Win32InputState) : Event?
        case event.event_type
        when Windows::KEY_EVENT
          kevent = event.key_event
          parse_win32_input_key_event(
            key_state,
            kevent.virtual_key_code,
            kevent.virtual_scan_code,
            kevent.char,
            kevent.key_down,
            kevent.control_key_state,
            kevent.repeat_count
          )
        when Windows::WINDOW_BUFFER_SIZE_EVENT
          wevent = event.window_buffer_size_event
          if wevent.size.x != key_state.last_winsize_x || wevent.size.y != key_state.last_winsize_y
            key_state.last_winsize_x = wevent.size.x
            key_state.last_winsize_y = wevent.size.y
            WindowSizeEvent.new(width: wevent.size.x.to_i, height: wevent.size.y.to_i)
          end
        when Windows::MOUSE_EVENT
          mevent = event.mouse_event
          ev = mouse_event(key_state.last_mouse_btns, mevent)
          key_state.last_mouse_btns = mevent.button_state
          ev
        when Windows::FOCUS_EVENT
          fevent = event.focus_event
          fevent.set_focus ? FocusEvent.new : BlurEvent.new
        when Windows::MENU_EVENT
          nil
        else
          nil
        end
      end

      private def mouse_event_button(previous : UInt32, state : UInt32) : {MouseButton, Bool}
        is_release = false
        button = MouseNone
        btn = previous ^ state
        is_release = true if (btn & state) == 0

        if btn == 0
          case
          when (state & Windows::FROM_LEFT_1ST_BUTTON_PRESSED) > 0
            button = MouseLeft
          when (state & Windows::FROM_LEFT_2ND_BUTTON_PRESSED) > 0
            button = MouseMiddle
          when (state & Windows::RIGHTMOST_BUTTON_PRESSED) > 0
            button = MouseRight
          when (state & Windows::FROM_LEFT_3RD_BUTTON_PRESSED) > 0
            button = MouseBackward
          when (state & Windows::FROM_LEFT_4TH_BUTTON_PRESSED) > 0
            button = MouseForward
          end
          return {button, is_release}
        end

        case btn
        when Windows::FROM_LEFT_1ST_BUTTON_PRESSED
          button = MouseLeft
        when Windows::RIGHTMOST_BUTTON_PRESSED
          button = MouseRight
        when Windows::FROM_LEFT_2ND_BUTTON_PRESSED
          button = MouseMiddle
        when Windows::FROM_LEFT_3RD_BUTTON_PRESSED
          button = MouseBackward
        when Windows::FROM_LEFT_4TH_BUTTON_PRESSED
          button = MouseForward
        end

        {button, is_release}
      end

      private def mouse_event(previous : UInt32, e : Windows::MouseEventRecord) : Event
        mod = KeyMod::None
        if (e.control_key_state & (Windows::LEFT_ALT_PRESSED | Windows::RIGHT_ALT_PRESSED)) != 0
          mod |= ModAlt
        end
        if (e.control_key_state & (Windows::LEFT_CTRL_PRESSED | Windows::RIGHT_CTRL_PRESSED)) != 0
          mod |= ModCtrl
        end
        if (e.control_key_state & Windows::SHIFT_PRESSED) != 0
          mod |= ModShift
        end

        m = Mouse.new(
          x: e.mouse_position.x.to_i,
          y: e.mouse_position.y.to_i,
          button: MouseNone,
          mod: mod
        )

        wheel_raw = high_word(e.button_state).to_i
        wheel_direction = wheel_raw >= 0x8000 ? wheel_raw - 0x10000 : wheel_raw

        case e.event_flags
        when 0_u32, Windows::DOUBLE_CLICK
          button, is_release = mouse_event_button(previous, e.button_state)
          m.button = button
          if (button >= MouseWheelUp && button <= MouseWheelRight)
            return MouseWheelEvent.new(m)
          elsif is_release
            return MouseReleaseEvent.new(m)
          else
            return MouseClickEvent.new(m)
          end
        when Windows::MOUSE_WHEELED
          m.button = wheel_direction > 0 ? MouseWheelUp : MouseWheelDown
          return MouseWheelEvent.new(m)
        when Windows::MOUSE_HWHEELED
          m.button = wheel_direction > 0 ? MouseWheelRight : MouseWheelLeft
          return MouseWheelEvent.new(m)
        when Windows::MOUSE_MOVED
          button, _ = mouse_event_button(previous, e.button_state)
          m.button = button
          return MouseMotionEvent.new(m)
        else
          return MouseMotionEvent.new(m)
        end
      end

      private def high_word(data : UInt32) : UInt16
        ((data & 0xFFFF0000_u32) >> 16).to_u16
      end

      # Parses a Win32 key event from Windows Console API input records.
      def parse_win32_input_key_event(state : Win32InputState, vkc : UInt16, _sc : UInt16, r : Char, key_down : Bool, cks : UInt32, repeat_count : UInt16) : Event?
        if state.utf16_half
          state.utf16_half = false
          state.utf16_buf[1] = r
          high = state.utf16_buf[0].ord
          low = state.utf16_buf[1].ord
          codepoint = ((high - 0xD800) << 10) + (low - 0xDC00) + 0x10000
          ch = codepoint.chr
          key = Key.new(
            code: ch.ord.to_u32,
            text: ch.to_s,
            mod: translate_control_key_state(cks)
          )
          key = ensure_key_case(key, cks)
          event = key_down ? KeyPressEvent.new(key).as(Event) : KeyReleaseEvent.new(key).as(Event)
          return repeat_event(event, repeat_count)
        end

        base_code = 0_u32
        case vkc
        when 0_u16
          if state.ansi_idx == 0 && r != Ansi::C0::ESC.chr
            base_code = r.ord.to_u32
          else
            state.ansi_buf[state.ansi_idx] = r.ord.to_u8
            state.ansi_idx += 1
            return nil if state.ansi_idx <= 2
            return nil if r == Ansi::C0::ESC.chr

            n, event = parse_sequence(state.ansi_buf.to_slice[0, state.ansi_idx])
            return nil if n == 0
            return nil if event.is_a?(UnknownEvent)
            state.ansi_idx = 0
            return event
          end
        when Windows::VK_SHIFT
          if (cks & Windows::SHIFT_PRESSED) != 0
            base_code = ((cks & Windows::ENHANCED_KEY) != 0 ? KeyRightShift : KeyLeftShift)
          elsif (state.last_cks & Windows::SHIFT_PRESSED) != 0
            base_code = ((state.last_cks & Windows::ENHANCED_KEY) != 0 ? KeyRightShift : KeyLeftShift)
          end
        when Windows::VK_CONTROL
          if (cks & Windows::LEFT_CTRL_PRESSED) != 0
            base_code = KeyLeftCtrl
          elsif (cks & Windows::RIGHT_CTRL_PRESSED) != 0
            base_code = KeyRightCtrl
          elsif (state.last_cks & Windows::LEFT_CTRL_PRESSED) != 0
            base_code = KeyLeftCtrl
          elsif (state.last_cks & Windows::RIGHT_CTRL_PRESSED) != 0
            base_code = KeyRightCtrl
          end
        when Windows::VK_MENU
          if (cks & Windows::LEFT_ALT_PRESSED) != 0
            base_code = KeyLeftAlt
          elsif (cks & Windows::RIGHT_ALT_PRESSED) != 0
            base_code = KeyRightAlt
          elsif (state.last_cks & Windows::LEFT_ALT_PRESSED) != 0
            base_code = KeyLeftAlt
          elsif (state.last_cks & Windows::RIGHT_ALT_PRESSED) != 0
            base_code = KeyRightAlt
          end
        else
          tmp = parse_win32_input_key_event(nil, vkc, _sc, r, key_down, cks, 1)
          if ev = tmp
            key = ev.as(KeyEvent).key
            base_code = key.base_code
            if base_code == 0
              base_code = key.code
            end
            state.last_cks = cks
            return repeat_event(ev, repeat_count)
          end
        end

        state.last_cks = cks
        return nil if base_code == 0

        key = Key.new(
          code: base_code,
          base_code: base_code,
          mod: translate_control_key_state(cks)
        )
        key = ensure_key_case(key, cks)
        event = key_down ? KeyPressEvent.new(key).as(Event) : KeyReleaseEvent.new(key).as(Event)
        repeat_event(event, repeat_count)
      end

      private def repeat_event(event : Event, repeat_count : UInt16) : Event
        return event if repeat_count <= 1
        MultiEvent.new(Array(Event).new(repeat_count.to_i) { event })
      end
    end
  {% end %}
end
