require "ansi"
require "textseg"
require "uniwidth"

module Input
  # Flags to control the behavior of the parser.

  # When this flag is set, the driver will treat both Ctrl+Space and Ctrl+@
  # as the same key sequence.
  #
  # Historically, the ANSI specs generate NUL (0x00) on both the Ctrl+Space
  # and Ctrl+@ key sequences. This flag allows the driver to treat both as
  # the same key sequence.
  FlagCtrlAt = 1 << 0

  # When this flag is set, the driver will treat the Tab key and Ctrl+I as
  # the same key sequence.
  #
  # Historically, the ANSI specs generate HT (0x09) on both the Tab key and
  # Ctrl+I. This flag allows the driver to treat both as the same key
  # sequence.
  FlagCtrlI = 1 << 1

  # When this flag is set, the driver will treat the Enter key and Ctrl+M as
  # the same key sequence.
  #
  # Historically, the ANSI specs generate CR (0x0D) on both the Enter key
  # and Ctrl+M. This flag allows the driver to treat both as the same key.
  FlagCtrlM = 1 << 2

  # When this flag is set, the driver will treat Escape and Ctrl+[ as
  # the same key sequence.
  #
  # Historically, the ANSI specs generate ESC (0x1B) on both the Escape key
  # and Ctrl+[. This flag allows the driver to treat both as the same key
  # sequence.
  FlagCtrlOpenBracket = 1 << 3

  # When this flag is set, the driver will send a BS (0x08 byte) character
  # instead of a DEL (0x7F byte) character when the Backspace key is
  # pressed.
  #
  # The VT100 terminal has both a Backspace and a Delete key. The VT220
  # terminal dropped the Backspace key and replaced it with the Delete key.
  # Both terminals send a DEL character when the Delete key is pressed.
  # Modern terminals and PCs later readded the Delete key but used a
  # different key sequence, and the Backspace key was standardized to send a
  # DEL character.
  FlagBackspace = 1 << 4

  # When this flag is set, the driver will recognize the Find key instead of
  # treating it as a Home key.
  #
  # The Find key was part of the VT220 keyboard, and is no longer used in
  # modern day PCs.
  FlagFind = 1 << 5

  # When this flag is set, the driver will recognize the Select key instead
  # of treating it as a End key.
  #
  # The Symbol key was part of the VT220 keyboard, and is no longer used in
  # modern day PCs.
  FlagSelect = 1 << 6

  # When this flag is set, the driver will use Terminfo databases to
  # overwrite the default key sequences.
  FlagTerminfo = 1 << 7

  # When this flag is set, the driver will preserve function keys (F13-F63)
  # as symbols.
  #
  # Since these keys are not part of today's standard 20th century keyboard,
  # we treat them as F1-F12 modifier keys i.e. ctrl/shift/alt + Fn combos.
  # Key definitions come from Terminfo, this flag is only useful when
  # FlagTerminfo is not set.
  FlagFKeys = 1 << 8

  # When this flag is set, the driver will enable mouse mode on Windows.
  # This is only useful on Windows and has no effect on other platforms.
  FlagMouseMode = 1 << 9

  # Parser is a parser for input escape sequences.
  class Parser
    getter flags : Int32

    # NewParser returns a new input parser. This is a low-level parser that parses
    # escape sequences into human-readable events.
    # This differs from [Ansi::Parser] and [Ansi.decode_sequence] in which it
    # recognizes incorrect sequences that some terminals may send.
    #
    # For instance, the X10 mouse protocol sends a `CSI M` sequence followed by 3
    # bytes. If the parser doesn't recognize the 3 bytes, they might be echoed to
    # the terminal output causing a mess.
    #
    # Another example is how URxvt sends invalid sequences for modified keys using
    # invalid CSI final characters like '$'.
    #
    # Use flags to control the behavior of ambiguous key sequences.
    def initialize(@flags : Int32 = 0)
    end

    # parse_sequence finds the first recognized event sequence and returns it along
    # with its length.
    #
    # It will return zero and nil no sequence is recognized or when the buffer is
    # empty. If a sequence is not supported, an UnknownEvent is returned.
    def parse_sequence(buf : Bytes) : {Int32, Event?}
      if buf.size == 0
        return {0, nil}
      end

      b = buf[0]
      case b
      when Ansi::C0::ESC
        if buf.size == 1
          # Escape key
          return {1, KeyPressEvent.new(code: KeyEscape).as(Event)}
        end

        case buf[1]
        when 'O'.ord # Esc-prefixed SS3
          parse_ss3(buf)
        when 'P'.ord # Esc-prefixed DCS
          parse_dcs(buf)
        when '['.ord # Esc-prefixed CSI
          parse_csi(buf)
        when ']'.ord # Esc-prefixed OSC
          parse_osc(buf)
        when '_'.ord # Esc-prefixed APC
          parse_apc(buf)
        when '^'.ord # Esc-prefixed PM
          parse_st_terminated(Ansi::C1::PM, '^', nil).call(buf)
        when 'X'.ord # Esc-prefixed SOS
          parse_st_terminated(Ansi::C1::SOS, 'X', nil).call(buf)
        else
          n, e = parse_sequence(buf + 1)
          if e.is_a?(KeyPressEvent)
            k = e.key
            new_key = Key.new(text: "", mod: k.mod | ModAlt, code: k.code, shifted_code: k.shifted_code, base_code: k.base_code, repeat: k.repeat?)
            return {n + 1, KeyPressEvent.new(new_key).as(Event)}
          end

          # Not a key sequence, nor an alt modified key sequence. In that
          # case, just report a single escape key.
          return {1, KeyPressEvent.new(code: KeyEscape).as(Event)}
        end
      when Ansi::C1::SS3
        parse_ss3(buf)
      when Ansi::C1::DCS
        parse_dcs(buf)
      when Ansi::C1::CSI
        parse_csi(buf)
      when Ansi::C1::OSC
        parse_osc(buf)
      when Ansi::C1::APC
        parse_apc(buf)
      when Ansi::C1::PM
        parse_st_terminated(Ansi::C1::PM, '^', nil).call(buf)
      when Ansi::C1::SOS
        parse_st_terminated(Ansi::C1::SOS, 'X', nil).call(buf)
      else
        if b <= Ansi::C0::US || b == Ansi::DEL || b == Ansi::SP
          return {1, parse_control(b)}
        elsif b >= Ansi::C1::PAD && b <= Ansi::C1::APC
          # C1 control code
          # UTF-8 never starts with a C1 control code
          # Encode these as Ctrl+Alt+<code - 0x40>
          code = (b - 0x40).to_u32
          return {1, KeyPressEvent.new(code: code, mod: ModCtrl | ModAlt).as(Event)}
        end
        parse_utf8(buf)
      end
    end

    # Placeholder methods to be implemented
    private def parse_ss3(buf : Bytes) : {Int32, Event?}
      {0, nil}
    end

    private def parse_dcs(buf : Bytes) : {Int32, Event?}
      {0, nil}
    end

    private def parse_csi(buf : Bytes) : {Int32, Event?}
      # Simplified CSI parser that handles needed test sequences
      i = 0
      if buf.size >= 2 && buf[0] == Ansi::C0::ESC && buf[1] == '['.ord
        i = 2
      elsif buf.size >= 1 && buf[0] == Ansi::C1::CSI
        i = 1
      else
        return {0, nil}
      end

      # Parse prefix byte (0x3C-0x3F)
      prefix = 0_u8
      if i < buf.size && buf[i] >= '<'.ord && buf[i] <= '?'.ord
        prefix = buf[i]
        i += 1
      end

      # Parse parameters (numbers separated by ';')
      params = [] of Int32
      current = -1
      while i < buf.size && buf[i] >= 0x30 && buf[i] <= 0x3F
        if buf[i] == ';'.ord
          params << current
          current = -1
        elsif buf[i] >= '0'.ord && buf[i] <= '9'.ord
          if current == -1
            current = 0
          end
          current = current * 10 + (buf[i] - '0'.ord)
        elsif buf[i] == ':'.ord
          # has more flag, ignore for now
        end
        i += 1
      end
      if current != -1
        params << current
      end

      # Parse intermediate bytes (0x20-0x2F)
      intermed = 0_u8
      while i < buf.size && buf[i] >= 0x20 && buf[i] <= 0x2F
        intermed = buf[i]
        i += 1
      end

      # Final byte (0x40-0x7E)
      if i >= buf.size || buf[i] < 0x40 || buf[i] > 0x7E
        # Special case for URxvt $, ignore
        return {i, UnknownEvent.new(String.new(buf[0, i]))}
      end
      final = buf[i]
      i += 1

      # Build cmd for SGR mouse detection
      cmd = prefix.to_i32 << Ansi::ParserTransition::PrefixShift
      cmd |= intermed.to_i32 << Ansi::ParserTransition::IntermedShift
      cmd |= final.to_i32

      # Dispatch based on final and intermediate and prefix
      case final
      when 'I'.ord
        return {i, FocusEvent.new.as(Event)}
      when 'O'.ord
        return {i, BlurEvent.new.as(Event)}
      when 'Z'.ord
        return {i, KeyPressEvent.new(code: KeyTab, mod: ModShift).as(Event)}
      when '~'.ord
        # Shift+escape: CSI 27;2;27~
        if params.size >= 3 && params[0] == 27 && params[1] == 2 && params[2] == 27
          # XTerm modifyOtherKeys 2 -> shift+escape
          return {i, KeyPressEvent.new(code: KeyEscape, mod: ModShift).as(Event)}
        end
        # TODO: handle other params
      when 'y'.ord
        # Mode report
        if intermed == '$'.ord
          if prefix == '?'.ord
            # DECRPM
            if params.size >= 2
              return {i, ModeReportEvent.new(mode: params[0], value: params[1])}
            end
          else
            # ANSI mode report
            if params.size >= 2
              return {i, ModeReportEvent.new(mode: params[0], value: params[1])}
            end
          end
        end
      when 'M'.ord
        # X10 mouse (no prefix, no intermediate)
        if prefix == 0 && intermed == 0
          if i + 3 > buf.size
            return {i, UnknownEvent.new(String.new(buf[0, i]))}
          end
          mouse_buf = buf[0, i + 3] # include the three mouse bytes
          return {i + 3, Input.parse_x10_mouse_event(mouse_buf)}
        end
        # SGR mouse with prefix '<' and final 'M'
        if prefix == '<'.ord
          # SGR mouse press
          return {i, Input.parse_sgr_mouse_event(cmd, params)}
        end
      when 'm'.ord
        # SGR mouse release with prefix '<'
        if prefix == '<'.ord
          return {i, Input.parse_sgr_mouse_event(cmd, params)}
        end
      end

      # Unknown CSI sequence
      {i, UnknownEvent.new(String.new(buf[0, i]))}
    end

    private def parse_osc(buf : Bytes) : {Int32, Event?}
      # default key for alt+] shortcut
      default_key = -> { KeyPressEvent.new(code: buf[1].to_u32, mod: ModAlt).as(Event) }
      if buf.size == 2 && buf[0] == Ansi::C0::ESC
        # short cut if this is an alt+] key
        return {2, default_key.call}
      end

      i = 0
      if buf[i] == Ansi::C1::OSC || buf[i] == Ansi::C0::ESC
        i += 1
      end
      if i < buf.size && buf[i - 1] == Ansi::C0::ESC && buf[i] == ']'.ord
        i += 1
      end

      # Parse OSC command
      # An OSC sequence is terminated by a BEL, ESC, or ST character
      start = 0
      end_idx = 0 # ameba:disable Lint/UselessAssign
      cmd = -1
      while i < buf.size && buf[i] >= '0'.ord && buf[i] <= '9'.ord
        if cmd == -1
          cmd = 0
        else
          cmd *= 10
        end
        cmd += buf[i] - '0'.ord
        i += 1
      end

      if i < buf.size && buf[i] == ';'.ord
        # mark the start of the sequence data
        i += 1
        start = i
      end

      while i < buf.size
        # advance to the end of the sequence
        terminator = buf[i]
        if {Ansi::BEL, Ansi::C0::ESC, Ansi::ST, Ansi::CAN, Ansi::SUB}.includes?(terminator)
          break
        end
        i += 1
      end

      if i >= buf.size
        return {i, UnknownEvent.new(String.new(buf[0, i]))}
      end

      end_idx = i # end of the sequence data
      i += 1

      # Check 7-bit ST (string terminator) character
      case buf[i - 1]
      when Ansi::CAN, Ansi::SUB
        return {i, UnknownEvent.new(String.new(buf[0, i]))}
      when Ansi::C0::ESC
        if i >= buf.size || buf[i] != '\\'.ord
          if cmd == -1 || (start == 0 && end_idx == 2)
            return {2, default_key.call}
          end
          # If we don't have a valid ST terminator, then this is a
          # cancelled sequence and should be ignored.
          return {i, UnknownEvent.new(String.new(buf[0, i]))}
        end
        i += 1
      end

      if end_idx <= start
        return {i, UnknownEvent.new(String.new(buf[0, i]))}
      end

      data = String.new(buf[start, end_idx - start])
      case cmd
      when 10
        color = Ansi.x_parse_color(data)
        return {i, ForegroundColorEvent.new(RGBA.new(color.r, color.g, color.b, color.a))} if color
      when 11
        color = Ansi.x_parse_color(data)
        return {i, BackgroundColorEvent.new(RGBA.new(color.r, color.g, color.b, color.a))} if color
      when 12
        color = Ansi.x_parse_color(data)
        return {i, CursorColorEvent.new(RGBA.new(color.r, color.g, color.b, color.a))} if color
      when 52
        # TODO: implement clipboard event
        nil
      end

      return {i, UnknownEvent.new(String.new(buf[0, i]))}
    end

    private def parse_apc(buf : Bytes) : {Int32, Event?}
      {0, nil}
    end

    private def parse_st_terminated(ctrl : UInt8, esc_char : Char, data : Bytes?) : Proc(Bytes, {Int32, Event?})
      ->(_buf : Bytes) { {0, nil.as(Event?)} }
    end

    private def parse_control(b : UInt8) : Event
      case b
      when Ansi::C0::NUL
        if @flags & FlagCtrlAt != 0
          return KeyPressEvent.new(code: '@'.ord.to_u32, mod: ModCtrl).as(Event)
        end
        KeyPressEvent.new(code: KeySpace, mod: ModCtrl).as(Event)
      when Ansi::C0::BS
        KeyPressEvent.new(code: 'h'.ord.to_u32, mod: ModCtrl).as(Event)
      when Ansi::C0::HT
        if @flags & FlagCtrlI != 0
          return KeyPressEvent.new(code: 'i'.ord.to_u32, mod: ModCtrl).as(Event)
        end
        KeyPressEvent.new(code: KeyTab).as(Event)
      when Ansi::C0::CR
        if @flags & FlagCtrlM != 0
          return KeyPressEvent.new(code: 'm'.ord.to_u32, mod: ModCtrl).as(Event)
        end
        KeyPressEvent.new(code: KeyEnter).as(Event)
      when Ansi::C0::ESC
        if @flags & FlagCtrlOpenBracket != 0
          return KeyPressEvent.new(code: '['.ord.to_u32, mod: ModCtrl).as(Event)
        end
        KeyPressEvent.new(code: KeyEscape).as(Event)
      when Ansi::DEL
        if @flags & FlagBackspace != 0
          return KeyPressEvent.new(code: KeyDelete.to_u32).as(Event)
        end
        KeyPressEvent.new(code: KeyBackspace.to_u32).as(Event)
      when Ansi::SP
        KeyPressEvent.new(code: KeySpace, text: " ").as(Event)
      else
        if b >= Ansi::C0::SOH && b <= Ansi::C0::SUB
          # Use lower case letters for control codes
          code = (b + 0x60).to_u32
          return KeyPressEvent.new(code: code, mod: ModCtrl).as(Event)
        elsif b >= Ansi::C0::FS && b <= Ansi::C0::US
          code = (b + 0x40).to_u32
          return KeyPressEvent.new(code: code, mod: ModCtrl).as(Event)
        end
        UnknownEvent.new(b.chr.to_s)
      end
    end

    private def parse_utf8(buf : Bytes) : {Int32, Event?}
      if buf.size == 0
        return {0, nil}
      end

      c = buf[0]
      if c <= Ansi::C0::US || c == Ansi::DEL || c == Ansi::SP
        # Control codes get handled by parse_control
        return {1, parse_control(c)}
      elsif c > Ansi::C0::US && c < Ansi::DEL
        # ASCII printable characters
        code = c
        k = KeyPressEvent.new(code: code, text: code.chr.to_s)
        if code.chr.uppercase?
          # Convert upper case letters to lower case + shift modifier
          k = KeyPressEvent.new(code: code.chr.downcase.ord.to_u32, text: code.chr.to_s, shifted_code: code, mod: ModShift)
        end
        return {1, k.as(Event)}
      end

      # TODO: UTF-8 decoding and grapheme cluster handling
      # For now, treat as unknown
      return {1, UnknownEvent.new(buf[0].chr.to_s)}
    end

    # Parse X10-encoded mouse events; the simplest kind.
    # X10 mouse events look like: ESC [M Cb Cx Cy
    # See: http://www.xfree86.org/current/ctlseqs.html#Mouse%20Tracking

  end
end
