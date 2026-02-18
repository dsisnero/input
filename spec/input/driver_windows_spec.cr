require "../spec_helper"
require "ansi/c0"

module Input
  {% if flag?(:windows) %}
    require "../../src/input/windows"

    # Helper functions for encoding Windows input records
    private module WindowsHelpers
      extend self

      def bool_to_uint32(b : Bool) : UInt32
        b ? 1_u32 : 0_u32
      end

      def encode_key_event(key : Windows::KeyEventRecord) : Windows::InputRecord
        bts = uninitialized StaticArray(UInt8, 16)
        ptr = bts.to_unsafe.as(Pointer(UInt8))
        # KeyDown (uint32)
        ptr.as(Pointer(UInt32)).value = bool_to_uint32(key.key_down)
        # RepeatCount (uint16)
        (ptr + 4).as(Pointer(UInt16)).value = key.repeat_count
        # VirtualKeyCode (uint16)
        (ptr + 6).as(Pointer(UInt16)).value = key.virtual_key_code
        # VirtualScanCode (uint16)
        (ptr + 8).as(Pointer(UInt16)).value = key.virtual_scan_code
        # Char (uint16)
        (ptr + 10).as(Pointer(UInt16)).value = key.char.ord.to_u16
        # ControlKeyState (uint32)
        (ptr + 12).as(Pointer(UInt32)).value = key.control_key_state
        Windows::InputRecord.new(event_type: Windows::KEY_EVENT, event: bts)
      end

      def encode_mouse_event(mouse : Windows::MouseEventRecord) : Windows::InputRecord
        bts = uninitialized StaticArray(UInt8, 16)
        ptr = bts.to_unsafe.as(Pointer(UInt8))
        # X (uint16)
        ptr.as(Pointer(UInt16)).value = mouse.mouse_position.x.to_u16
        # Y (uint16)
        (ptr + 2).as(Pointer(UInt16)).value = mouse.mouse_position.y.to_u16
        # ButtonState (uint32)
        (ptr + 4).as(Pointer(UInt32)).value = mouse.button_state
        # ControlKeyState (uint32)
        (ptr + 8).as(Pointer(UInt32)).value = mouse.control_key_state
        # EventFlags (uint32)
        (ptr + 12).as(Pointer(UInt32)).value = mouse.event_flags
        Windows::InputRecord.new(event_type: Windows::MOUSE_EVENT, event: bts)
      end

      def encode_focus_event(focus : Windows::FocusEventRecord) : Windows::InputRecord
        bts = uninitialized StaticArray(UInt8, 16)
        if focus.set_focus
          bts[0] = 1_u8
        end
        Windows::InputRecord.new(event_type: Windows::FOCUS_EVENT, event: bts)
      end

      def encode_window_buffer_size_event(size : Windows::WindowBufferSizeRecord) : Windows::InputRecord
        bts = uninitialized StaticArray(UInt8, 16)
        ptr = bts.to_unsafe.as(Pointer(UInt8))
        ptr.as(Pointer(UInt16)).value = size.size.x.to_u16
        (ptr + 2).as(Pointer(UInt16)).value = size.size.y.to_u16
        Windows::InputRecord.new(event_type: Windows::WINDOW_BUFFER_SIZE_EVENT, event: bts)
      end

      def encode_menu_event(menu : Windows::MenuEventRecord) : Windows::InputRecord
        bts = uninitialized StaticArray(UInt8, 16)
        ptr = bts.to_unsafe.as(Pointer(UInt8))
        ptr.as(Pointer(UInt32)).value = menu.command_id
        Windows::InputRecord.new(event_type: Windows::MENU_EVENT, event: bts)
      end

      # encodeSequence encodes a string of ANSI escape sequences into a slice of
      # Windows input key records.
      def encode_sequence(s : String) : Array(Windows::InputRecord)
        evs = [] of Windows::InputRecord
        state = 0_u8
        input = s
        until input.empty?
          seq, _, n, new_state = Ansi.decode_sequence(input, state)
          seq.each_byte do |b|
            evs << encode_key_event(Windows::KeyEventRecord.new(
              key_down: true,
              repeat_count: 1,
              virtual_key_code: 0,
              virtual_scan_code: 0,
              char: b.chr,
              control_key_state: 0
            ))
          end
          break if n <= 0
          state = new_state
          input = input.byte_slice(n, input.bytesize - n)
        end
        evs
      end

      def encode_utf16_rune(r : Char) : Array(Windows::InputRecord)
        # UTF-16 encoding: for runes <= 0xFFFF, single char; else surrogate pair
        codepoint = r.ord
        if codepoint <= 0xFFFF
          [encode_key_event(Windows::KeyEventRecord.new(
            key_down: true,
            repeat_count: 1,
            virtual_key_code: 0,
            virtual_scan_code: 0,
            char: r,
            control_key_state: 0
          ))]
        else
          # Encode as UTF-16 surrogate pair
          # Formula: let u = codepoint - 0x10000
          # high = (u >> 10) + 0xD800
          # low = (u & 0x3FF) + 0xDC00
          u = codepoint - 0x10000
          high = (u >> 10) + 0xD800
          low = (u & 0x3FF) + 0xDC00
          encode_utf16_pair(high.chr, low.chr)
        end
      end

      def encode_utf16_pair(r1 : Char, r2 : Char) : Array(Windows::InputRecord)
        [
          encode_key_event(Windows::KeyEventRecord.new(
            key_down: true,
            repeat_count: 1,
            virtual_key_code: 0,
            virtual_scan_code: 0,
            char: r1,
            control_key_state: 0
          )),
          encode_key_event(Windows::KeyEventRecord.new(
            key_down: true,
            repeat_count: 1,
            virtual_key_code: 0,
            virtual_scan_code: 0,
            char: r2,
            control_key_state: 0
          )),
        ]
      end
    end

    describe "WindowsInputEvents" do
      include WindowsHelpers

      # Test cases ported from Go's TestWindowsInputEvents
      cases = [
        {
          name:   "single key event",
          events: [encode_key_event(Windows::KeyEventRecord.new(
            key_down: true,
            repeat_count: 1,
            virtual_key_code: 'A'.ord.to_u16,
            virtual_scan_code: 0,
            char: 'a',
            control_key_state: 0
          ))],
          expected: [KeyPressEvent.new(code: 'a'.ord.to_u32, base_code: 'a'.ord.to_u32, text: "a")],
          sequence: false,
        },
        {
          name:   "single key event with control key",
          events: [encode_key_event(Windows::KeyEventRecord.new(
            key_down: true,
            repeat_count: 1,
            virtual_key_code: 'A'.ord.to_u16,
            virtual_scan_code: 0,
            char: 'a',
            control_key_state: Windows::LEFT_CTRL_PRESSED,
          ))],
          expected: [KeyPressEvent.new(code: 'a'.ord.to_u32, base_code: 'a'.ord.to_u32, mod: ModCtrl)],
          sequence: false,
        },
        {
          name:   "escape alt key event",
          events: [encode_key_event(Windows::KeyEventRecord.new(
            key_down: true,
            repeat_count: 1,
            virtual_key_code: Ansi::C0::ESC.ord.to_u16, # 0x1B
            virtual_scan_code: 0,
            char: Ansi::C0::ESC.chr,
            control_key_state: Windows::LEFT_ALT_PRESSED,
          ))],
          expected: [KeyPressEvent.new(code: KeyEscape, base_code: KeyEscape, mod: ModAlt)],
          sequence: false,
        },
        {
          name:   "single shifted key event",
          events: [encode_key_event(Windows::KeyEventRecord.new(
            key_down: true,
            repeat_count: 1,
            virtual_key_code: 'A'.ord.to_u16,
            virtual_scan_code: 0,
            char: 'A',
            control_key_state: Windows::SHIFT_PRESSED,
          ))],
          expected: [KeyPressEvent.new(code: 'A'.ord.to_u32, base_code: 'a'.ord.to_u32, text: "A", mod: ModShift)],
          sequence: false,
        },
        {
          name:     "utf16 rune",
          events:   encode_utf16_rune('😊'), # smiley emoji '😊'
          expected: [KeyPressEvent.new(code: '😊'.ord.to_u32, text: "😊")],
          sequence: true,
        },
        {
          name:     "background color response",
          events:   encode_sequence("\e]11;rgb:ff/ff/ff\a"),
          expected: [BackgroundColorEvent.new(color: RGBA.new(0xff, 0xff, 0xff, 0xff))],
          sequence: true,
        },
        {
          name:     "st terminated background color response",
          events:   encode_sequence("\e]11;rgb:ffff/ffff/ffff\e\\"),
          expected: [BackgroundColorEvent.new(color: RGBA.new(0xff, 0xff, 0xff, 0xff))],
          sequence: true,
        },
        {
          name:   "simple mouse event",
          events: [
            encode_mouse_event(Windows::MouseEventRecord.new(
              mouse_position: Windows::Coord.new(x: 10_i16, y: 20_i16),
              button_state: Windows::FROM_LEFT_1ST_BUTTON_PRESSED,
              control_key_state: 0,
              event_flags: 0
            )),
            encode_mouse_event(Windows::MouseEventRecord.new(
              mouse_position: Windows::Coord.new(x: 10_i16, y: 20_i16),
              button_state: 0,
              control_key_state: 0,
              event_flags: 0
            )),
          ],
          expected: [
            MouseClickEvent.new(button: MouseLeft, x: 10, y: 20),
            MouseReleaseEvent.new(button: MouseLeft, x: 10, y: 20),
          ],
          sequence: false,
        },
        {
          name:   "focus event",
          events: [
            encode_focus_event(Windows::FocusEventRecord.new(set_focus: true)),
            encode_focus_event(Windows::FocusEventRecord.new(set_focus: false)),
          ],
          expected: [
            FocusEvent.new,
            BlurEvent.new,
          ],
          sequence: false,
        },
        {
          name:   "window size event",
          events: [encode_window_buffer_size_event(Windows::WindowBufferSizeRecord.new(
            size: Windows::Coord.new(x: 10_i16, y: 20_i16)
          ))],
          expected: [WindowSizeEvent.new(width: 10, height: 20)],
          sequence: false,
        },
      ]

      cases.each do |tc|
        it tc[:name] do
          parser = Parser.new(0)
          state = Win32InputState.new

          if tc[:sequence]
            event = nil.as(Event?)
            tc[:events].each do |ev|
              ev.event_type.should eq Windows::KEY_EVENT
              key = ev.key_event
              event = parser.parse_win32_input_key_event(
                state,
                key.virtual_key_code,
                key.virtual_scan_code,
                key.char,
                key.key_down,
                key.control_key_state,
                key.repeat_count
              )
            end
            tc[:expected].size.should eq 1
            event.should eq tc[:expected][0]
          else
            tc[:events].size.should eq tc[:expected].size
            tc[:events].each_with_index do |ev, i|
              parser.parse_con_input_event(ev, state).should eq tc[:expected][i]
            end
          end
        end
      end
    end
  {% else %}
    pending "Windows driver tests (Windows only)" do
    end
  {% end %}
end
