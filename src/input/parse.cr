require "ansi"
require "textseg"
require "uniwidth"
require "base64"

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

    private def parse_ss3(buf : Bytes) : {Int32, Event?}
      # short cut if this is an alt+O key
      if buf.size == 2 && buf[0] == Ansi::C0::ESC
        return {2, KeyPressEvent.new(code: buf[1].to_u32, mod: ModAlt).as(Event)}
      end

      i = 0
      if buf[i] == Ansi::C1::SS3 || buf[i] == Ansi::C0::ESC
        i += 1
      end
      if i < buf.size && buf[i - 1] == Ansi::C0::ESC && buf[i] == 'O'.ord
        i += 1
      end

      # Scan numbers from 0-9
      mod = 0
      while i < buf.size && buf[i] >= '0'.ord && buf[i] <= '9'.ord
        mod *= 10
        mod += buf[i] - '0'.ord
        i += 1
      end

      # Scan a GL character
      # A GL character is a single byte in the range 0x21-0x7E
      # See https://vt100.net/docs/vt220-rm/chapter2.html#S2.3.2
      if i >= buf.size || buf[i] < 0x21 || buf[i] > 0x7E
        return {i, UnknownEvent.new(String.new(buf[0, i]))}
      end

      # GL character(s)
      gl = buf[i]
      i += 1

      k = KeyPressEvent.new(code: 0, mod: KeyMod::None)
      case gl
      when 'a'.ord, 'b'.ord, 'c'.ord, 'd'.ord
        k = KeyPressEvent.new(code: KeyUp + (gl - 'a'.ord).to_u32, mod: ModCtrl)
      when 'A'.ord, 'B'.ord, 'C'.ord, 'D'.ord
        k = KeyPressEvent.new(code: KeyUp + (gl - 'A'.ord).to_u32, mod: KeyMod::None)
      when 'E'.ord
        k = KeyPressEvent.new(code: KeyBegin, mod: KeyMod::None)
      when 'F'.ord
        k = KeyPressEvent.new(code: KeyEnd, mod: KeyMod::None)
      when 'H'.ord
        k = KeyPressEvent.new(code: KeyHome, mod: KeyMod::None)
      when 'P'.ord, 'Q'.ord, 'R'.ord, 'S'.ord
        k = KeyPressEvent.new(code: KeyF1 + (gl - 'P'.ord).to_u32, mod: KeyMod::None)
      when 'M'.ord
        k = KeyPressEvent.new(code: KeyKpEnter, mod: KeyMod::None)
      when 'X'.ord
        k = KeyPressEvent.new(code: KeyKpEqual, mod: KeyMod::None)
      when 'j'.ord, 'k'.ord, 'l'.ord, 'm'.ord, 'n'.ord, 'o'.ord, 'p'.ord, 'q'.ord, 'r'.ord, 's'.ord, 't'.ord, 'u'.ord, 'v'.ord, 'w'.ord, 'x'.ord, 'y'.ord
        k = KeyPressEvent.new(code: KeyKpMultiply + (gl - 'j'.ord).to_u32, mod: KeyMod::None)
      else
        return {i, UnknownEvent.new(String.new(buf[0, i]))}
      end

      # Handle weird SS3 <modifier> Func
      if mod > 0
        key = k.key
        k = KeyPressEvent.new(text: key.text, mod: key.mod | KeyMod.new((mod - 1).to_u32), code: key.code, shifted_code: key.shifted_code, base_code: key.base_code, is_repeat: key.repeat?)
      end

      {i, k.as(Event)}
    end

    private def parse_dcs(buf : Bytes) : {Int32, Event?}
      if buf.size == 2 && buf[0] == Ansi::C0::ESC
        # short cut if this is an alt+P key
        return {2, KeyPressEvent.new(code: 'p'.ord.to_u32, mod: ModShift | ModAlt).as(Event)}
      end

      params = Array(Int32).new(16, Ansi::ParserTransition::MissingParam)
      params_len = 0
      cmd = 0_i32

      # DCS sequences are introduced by DCS (0x90) or ESC P (0x1b 0x50)
      i = 0
      if buf[i] == Ansi::C1::DCS || buf[i] == Ansi::C0::ESC
        i += 1
      end
      if i < buf.size && buf[i - 1] == Ansi::C0::ESC && buf[i] == 'P'.ord
        i += 1
      end

      # initial DCS byte
      if i < buf.size && buf[i] >= '<'.ord && buf[i] <= '?'.ord
        cmd |= (buf[i].to_i32) << Ansi::ParserTransition::PrefixShift
      end

      # Scan parameter bytes in the range 0x30-0x3F
      j = 0
      while i < buf.size && params_len < params.size && buf[i] >= 0x30 && buf[i] <= 0x3F
        if buf[i] >= '0'.ord && buf[i] <= '9'.ord
          if params[params_len] == Ansi::ParserTransition::MissingParam
            params[params_len] = 0
          end
          params[params_len] *= 10
          params[params_len] += buf[i] - '0'.ord
        end
        if buf[i] == ':'.ord
          params[params_len] |= Ansi::ParserTransition::HasMoreFlag
        end
        if buf[i] == ';'.ord || buf[i] == ':'.ord
          params_len += 1
          if params_len < params.size
            # Don't overflow the params slice
            params[params_len] = Ansi::ParserTransition::MissingParam
          end
        end
        i += 1
        j += 1
      end

      if j > 0 && params_len < params.size
        # has parameters
        params_len += 1
      end

      # Scan intermediate bytes in the range 0x20-0x2F
      intermed = 0_u8
      while i < buf.size && buf[i] >= 0x20 && buf[i] <= 0x2F
        intermed = buf[i]
        i += 1
      end

      # set intermediate byte
      cmd |= intermed.to_i32 << Ansi::ParserTransition::IntermedShift

      # Scan final byte in the range 0x40-0x7E
      if i >= buf.size || buf[i] < 0x40 || buf[i] > 0x7E
        return {i, UnknownEvent.new(String.new(buf[0, i]))}
      end

      # Add the final byte
      cmd |= buf[i].to_i32
      i += 1

      start = i # start of the sequence data
      while i < buf.size
        if buf[i] == Ansi::ST || buf[i] == Ansi::C0::ESC
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
      if i < buf.size && buf[i - 1] == Ansi::C0::ESC && buf[i] == '\\'.ord
        i += 1
      end

      pa = Ansi::Params.new(params[0, params_len])
      case cmd
      when 'r'.ord | ('+'.ord << Ansi::ParserTransition::IntermedShift)
        # XTGETTCAP responses
        param_value, _, ok = pa.param(0, 0)
        if ok && param_value == 1 # 1 means valid response, 0 means invalid response
          tc = Input.parse_termcap(buf[start, end_idx - start])
          # XXX: some terminals like KiTTY report invalid responses with
          # their queries i.e. sending a query for "Tc" using "\x1bP+q5463\x1b\\"
          # returns "\x1bP0+r5463\x1b\\".
          # The specs says that invalid responses should be in the form of
          # DCS 0 + r ST "\x1bP0+r\x1b\\"
          # We ignore invalid responses and only send valid ones to the program.
          #
          # See: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
          return {i, tc}
        end
      when '|'.ord | ('>'.ord << Ansi::ParserTransition::PrefixShift)
        # XTVersion response
        return {i, TerminalVersionEvent.new(String.new(buf[start, end_idx - start]))}
      end

      {i, UnknownEvent.new(String.new(buf[0, i]))}
    end

    private def parse_csi(buf : Bytes) : {Int32, Event?}
      if buf.size == 2 && buf[0] == Ansi::C0::ESC
        # Short cut if this is an alt+[ key.
        return {2, KeyPressEvent.new(text: buf[1].chr.to_s, mod: ModAlt).as(Event)}
      end

      cmd = 0_i32
      params = Array(Int32).new(Ansi::ParserTransition::MaxParamsSize, Ansi::ParserTransition::MissingParam)
      params_len = 0

      i = 0
      if buf[i] == Ansi::C1::CSI || buf[i] == Ansi::C0::ESC
        i += 1
      end
      if i < buf.size && buf[i - 1] == Ansi::C0::ESC && buf[i] == '['.ord
        i += 1
      end

      # Initial CSI byte.
      if i < buf.size && buf[i] >= '<'.ord && buf[i] <= '?'.ord
        cmd |= (buf[i].to_i32) << Ansi::ParserTransition::PrefixShift
      end

      # Scan parameter bytes in the range 0x30-0x3F.
      j = 0
      while i < buf.size && params_len < params.size && buf[i] >= 0x30 && buf[i] <= 0x3F
        if buf[i] >= '0'.ord && buf[i] <= '9'.ord
          if params[params_len] == Ansi::ParserTransition::MissingParam
            params[params_len] = 0
          end
          params[params_len] *= 10
          params[params_len] += buf[i] - '0'.ord
        end
        if buf[i] == ':'.ord
          params[params_len] |= Ansi::ParserTransition::HasMoreFlag
        end
        if buf[i] == ';'.ord || buf[i] == ':'.ord
          params_len += 1
          if params_len < params.size
            params[params_len] = Ansi::ParserTransition::MissingParam
          end
        end
        i += 1
        j += 1
      end

      if j > 0 && params_len < params.size
        params_len += 1
      end

      # Scan intermediate bytes in the range 0x20-0x2F.
      intermed = 0_u8
      while i < buf.size && buf[i] >= 0x20 && buf[i] <= 0x2F
        intermed = buf[i]
        i += 1
      end
      cmd |= intermed.to_i32 << Ansi::ParserTransition::IntermedShift

      # Scan final byte in the range 0x40-0x7E.
      if i >= buf.size || buf[i] < 0x40 || buf[i] > 0x7E
        # Special case for URxvt keys: CSI <number> $ as a shifted key.
        if i > 0 && buf[i - 1] == '$'.ord.to_u8
          nbuf = Array(UInt8).new(i)
          nbuf.concat(buf[0, i - 1])
          nbuf << '~'.ord.to_u8
          n, ev = parse_csi(Slice.new(nbuf.to_unsafe, nbuf.size))
          if ev.is_a?(KeyPressEvent)
            key = ev.key
            key.mod |= ModShift
            return {n, KeyPressEvent.new(key).as(Event)}
          end
          return {n, ev}
        end
        end_idx = i > 0 ? i - 1 : i
        return {i, UnknownEvent.new(String.new(buf[0, end_idx]))}
      end

      cmd |= buf[i].to_i32
      i += 1

      pa = Ansi::Params.new(params[0, params_len])
      case cmd
      when 'y'.ord | ('?'.ord << Ansi::ParserTransition::PrefixShift) | ('$'.ord << Ansi::ParserTransition::IntermedShift)
        mode, _, ok = pa.param(0, -1)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok && mode != -1
        value, _, ok = pa.param(1, -1)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok && value != -1
        return {i, ModeReportEvent.new(mode: mode, value: value)}
      when 'c'.ord | ('?'.ord << Ansi::ParserTransition::PrefixShift)
        return {i, Input.parse_primary_dev_attrs(pa)}
      when 'u'.ord | ('?'.ord << Ansi::ParserTransition::PrefixShift)
        flags, _, ok = pa.param(0, -1)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok && flags != -1
        return {i, KittyEnhancementsEvent.new(flags)}
      when 'R'.ord | ('?'.ord << Ansi::ParserTransition::PrefixShift)
        row, _, ok = pa.param(0, 1)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok
        col, _, ok = pa.param(1, 1)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok
        return {i, CursorPositionEvent.new(y: row - 1, x: col - 1)}
      when 'm'.ord | ('<'.ord << Ansi::ParserTransition::PrefixShift), 'M'.ord | ('<'.ord << Ansi::ParserTransition::PrefixShift)
        if params_len == 3
          return {i, Input.parse_sgr_mouse_event(cmd, pa.to_a)}
        end
      when 'm'.ord | ('>'.ord << Ansi::ParserTransition::PrefixShift)
        mok, _, ok = pa.param(0, 0)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok && mok == 4
        val, _, ok = pa.param(1, -1)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok && val != -1
        return {i, ModifyOtherKeysEvent.new(val)}
      when 'I'.ord
        return {i, FocusEvent.new}
      when 'O'.ord
        return {i, BlurEvent.new}
      when 'R'.ord
        row, _, rok = pa.param(0, 1)
        col, _, cok = pa.param(1, 1)
        if params_len == 2 && rok && cok
          m = CursorPositionEvent.new(y: row - 1, x: col - 1)
          if row == 1 && (col - 1) <= (ModMeta | ModShift | ModAlt | ModCtrl).value
            f3 = KeyPressEvent.new(code: KeyF3, mod: KeyMod.new((col - 1).to_u32))
            return {i, MultiEvent.new([f3.as(Event), m.as(Event)])}
          end
          return {i, m}
        end

        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless params_len == 0
        # Unmodified key F3 (CSI R); falls through to shared key handling.
        k = KeyPressEvent.new(code: KeyF3)
        return {i, Input.parse_kitty_keyboard_ext(pa, k)}
      when 'a'.ord, 'b'.ord, 'c'.ord, 'd'.ord, 'A'.ord, 'B'.ord, 'C'.ord, 'D'.ord, 'E'.ord, 'F'.ord, 'H'.ord, 'P'.ord, 'Q'.ord, 'S'.ord, 'Z'.ord
        k = KeyPressEvent.new(code: 0, mod: KeyMod::None)
        case cmd
        when 'a'.ord, 'b'.ord, 'c'.ord, 'd'.ord
          k = KeyPressEvent.new(code: KeyUp + (cmd - 'a'.ord).to_u32, mod: ModShift)
        when 'A'.ord, 'B'.ord, 'C'.ord, 'D'.ord
          k = KeyPressEvent.new(code: KeyUp + (cmd - 'A'.ord).to_u32)
        when 'E'.ord
          k = KeyPressEvent.new(code: KeyBegin)
        when 'F'.ord
          k = KeyPressEvent.new(code: KeyEnd)
        when 'H'.ord
          k = KeyPressEvent.new(code: KeyHome)
        when 'P'.ord, 'Q'.ord, 'R'.ord, 'S'.ord
          k = KeyPressEvent.new(code: KeyF1 + (cmd - 'P'.ord).to_u32)
        when 'Z'.ord
          k = KeyPressEvent.new(code: KeyTab, mod: ModShift)
        end

        id, _, _ = pa.param(0, 1)
        id = 1 if id == 0
        mod, _, _ = pa.param(1, 1)
        mod = 1 if mod == 0
        if params_len > 1 && id == 1 && mod != -1
          key = k.key
          key.mod |= KeyMod.new((mod - 1).to_u32)
          k = KeyPressEvent.new(key)
        end
        return {i, Input.parse_kitty_keyboard_ext(pa, k)}
      when 'M'.ord
        if i + 3 > buf.size
          return {i, UnknownEvent.new(String.new(buf[0, i]))}
        end
        return {i + 3, Input.parse_x10_mouse_event(buf[0, i + 3])}
      when 'y'.ord | ('$'.ord << Ansi::ParserTransition::IntermedShift)
        mode, _, ok = pa.param(0, -1)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok && mode != -1
        val, _, ok = pa.param(1, -1)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok && val != -1
        return {i, ModeReportEvent.new(mode: mode, value: val)}
      when 'u'.ord
        return {i, UnknownEvent.new(String.new(buf[0, i]))} if params_len == 0
        return {i, Input.parse_kitty_keyboard(pa)}
      when '_'.ord
        return {i, UnknownEvent.new(String.new(buf[0, i]))} if params_len != 6

        vrc, _, _ = pa.param(5, 0)
        rc = vrc.to_u16
        rc = 1_u16 if rc == 0

        vk, _, _ = pa.param(0, 0)
        sc, _, _ = pa.param(1, 0)
        uc, _, _ = pa.param(2, 0)
        kd, _, _ = pa.param(3, 0)
        cs, _, _ = pa.param(4, 0)
        event = parse_win32_input_key_event(
          nil,
          vk.to_u16,
          sc.to_u16,
          uc.chr,
          kd == 1,
          cs.to_u32,
          rc
        )
        return {i, UnknownEvent.new(String.new(buf))} if event.nil?
        return {i, event}
      when '@'.ord, '^'.ord, '~'.ord
        return {i, UnknownEvent.new(String.new(buf[0, i]))} if params_len == 0

        param, _, _ = pa.param(0, 0)
        if cmd == '~'.ord && param == 27
          return {i, UnknownEvent.new(String.new(buf[0, i]))} if params_len != 3
          return {i, Input.parse_xterm_modify_other_keys(pa)}
        elsif cmd == '~'.ord && param == 200
          return {i, PasteStartEvent.new}
        elsif cmd == '~'.ord && param == 201
          return {i, PasteEndEvent.new}
        end

        k = case param
            when 1
              KeyPressEvent.new(code: (@flags & FlagFind) != 0 ? KeyFind : KeyHome)
            when 2
              KeyPressEvent.new(code: KeyInsert)
            when 3
              KeyPressEvent.new(code: KeyDelete)
            when 4
              KeyPressEvent.new(code: (@flags & FlagSelect) != 0 ? KeySelect : KeyEnd)
            when 5
              KeyPressEvent.new(code: KeyPgUp)
            when 6
              KeyPressEvent.new(code: KeyPgDown)
            when 7
              KeyPressEvent.new(code: KeyHome)
            when 8
              KeyPressEvent.new(code: KeyEnd)
            when 11, 12, 13, 14, 15
              KeyPressEvent.new(code: KeyF1 + (param - 11).to_u32)
            when 17, 18, 19, 20, 21
              KeyPressEvent.new(code: KeyF6 + (param - 17).to_u32)
            when 23, 24, 25, 26
              KeyPressEvent.new(code: KeyF11 + (param - 23).to_u32)
            when 28, 29
              KeyPressEvent.new(code: KeyF15 + (param - 28).to_u32)
            when 31, 32, 33, 34
              KeyPressEvent.new(code: KeyF17 + (param - 31).to_u32)
            else
              nil
            end
        return {i, UnknownEvent.new(String.new(buf[0, i]))} if k.nil?

        mod, _, _ = pa.param(1, -1)
        if params_len > 1 && mod != -1
          key = k.key
          key.mod |= KeyMod.new((mod - 1).to_u32)
          k = KeyPressEvent.new(key)
        end

        case cmd
        when '~'.ord
          return {i, Input.parse_kitty_keyboard_ext(pa, k)}
        when '^'.ord
          key = k.key
          key.mod |= ModCtrl
          k = KeyPressEvent.new(key)
        when '@'.ord
          key = k.key
          key.mod |= ModCtrl | ModShift
          k = KeyPressEvent.new(key)
        end
        return {i, k}
      when 't'.ord
        param, _, ok = pa.param(0, 0)
        return {i, UnknownEvent.new(String.new(buf[0, i]))} unless ok

        args = [] of Int32
        (1...params_len).each do |jdx|
          val, _, ok = pa.param(jdx, 0)
          args << val if ok
        end
        return {i, WindowOpEvent.new(op: param, args: args)}
      end

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
        parts = data.split(';')
        if parts.empty?
          return {i, ClipboardEvent.new("", 0_u8)}
        end
        if parts.size != 2 || parts[0].empty?
          # fall through to unknown
        else
          b64 = parts[1]
          begin
            decoded = Base64.decode_string(b64)
          rescue
            # fall through
          else
            selection = parts[0][0].ord.to_u8
            return {i, ClipboardEvent.new(decoded, selection)}
          end
        end
      end

      return {i, UnknownEvent.new(String.new(buf[0, i]))}
    end

    private def parse_apc(buf : Bytes) : {Int32, Event?}
      if buf.size == 2 && buf[0] == Ansi::C0::ESC
        # short cut if this is an alt+_ key
        return {2, KeyPressEvent.new(code: buf[1].to_u32, mod: ModAlt).as(Event)}
      end

      # APC sequences are introduced by APC (0x9f) or ESC _ (0x1b 0x5f)
      parse_st_terminated(Ansi::C1::APC, '_', ->(b : Bytes) do
        ev = nil.as(Event?)
        if b.size > 0
          case b[0]
          when 'G'.ord.to_u8 # Kitty Graphics Protocol
            parts = String.new(b[1..]).split(';', 2)
            opts = Ansi::Kitty::Options.new
            opts.unmarshal_text(parts[0]) unless parts[0].empty?
            payload = parts.size > 1 ? parts[1] : ""
            ev = KittyGraphicsEvent.new(opts, payload).as(Event)
          end
        end

        ev
      end).call(buf)
    end

    private def parse_st_terminated(intro8 : UInt8, intro7 : Char, fn : Proc(Bytes, Event?)?) : Proc(Bytes, {Int32, Event?})
      default_key = ->(b : Bytes) do
        case intro8
        when Ansi::C1::SOS
          {2, KeyPressEvent.new(code: 'x'.ord.to_u32, mod: ModShift | ModAlt).as(Event)}
        when Ansi::C1::PM, Ansi::C1::APC
          {2, KeyPressEvent.new(code: b[1].to_u32, mod: ModAlt).as(Event)}
        else
          {0, nil.as(Event?)}
        end
      end

      ->(buf : Bytes) do
        if buf.size == 2 && buf[0] == Ansi::C0::ESC
          return default_key.call(buf)
        end

        i = 0
        if buf[i] == intro8 || buf[i] == Ansi::C0::ESC
          i += 1
        end
        if i < buf.size && buf[i - 1] == Ansi::C0::ESC && buf[i] == intro7.ord.to_u8
          i += 1
        end

        # Scan control sequence
        # Most common control sequence is terminated by a ST character
        # ST is a 7-bit string terminator character is (ESC \)
        start = i
        while i < buf.size
          if {Ansi::C0::ESC, Ansi::ST, Ansi::CAN, Ansi::SUB}.includes?(buf[i])
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
            if start == end_idx
              return default_key.call(buf)
            end

            # If we don't have a valid ST terminator, then this is a
            # cancelled sequence and should be ignored.
            return {i, UnknownEvent.new(String.new(buf[0, i]))}
          end
          i += 1
        end

        # Call the function to parse the sequence and return the result
        if fn
          if e = fn.call(buf[start, end_idx - start])
            return {i, e}
          end
        end

        {i, UnknownEvent.new(String.new(buf[0, i]))}
      end
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

    private def parse_win32_input_key_event(state : Nil, vkc : UInt16, _sc : UInt16, r : Char, key_down : Bool, cks : UInt32, repeat_count : UInt16) : Event?
      base_code = 0_u32

      case vkc
      when 0_u16
        # Zero means this event is either an escape code or a unicode codepoint.
        base_code = r.ord.to_u32
      when Windows::VK_BACK
        base_code = KeyBackspace
      when Windows::VK_TAB
        base_code = KeyTab
      when Windows::VK_RETURN
        base_code = KeyEnter
      when Windows::VK_PAUSE
        base_code = KeyPause
      when Windows::VK_CAPITAL
        base_code = KeyCapsLock
      when Windows::VK_ESCAPE
        base_code = KeyEscape
      when Windows::VK_SPACE
        base_code = KeySpace
      when Windows::VK_PRIOR
        base_code = KeyPgUp
      when Windows::VK_NEXT
        base_code = KeyPgDown
      when Windows::VK_END
        base_code = KeyEnd
      when Windows::VK_HOME
        base_code = KeyHome
      when Windows::VK_LEFT
        base_code = KeyLeft
      when Windows::VK_UP
        base_code = KeyUp
      when Windows::VK_RIGHT
        base_code = KeyRight
      when Windows::VK_DOWN
        base_code = KeyDown
      when Windows::VK_SELECT
        base_code = KeySelect
      when Windows::VK_SNAPSHOT
        base_code = KeyPrintScreen
      when Windows::VK_INSERT
        base_code = KeyInsert
      when Windows::VK_DELETE
        base_code = KeyDelete
      when '0'.ord.to_u16..'9'.ord.to_u16
        base_code = vkc.to_u32
      when 'A'.ord.to_u16..'Z'.ord.to_u16
        # Convert to lowercase.
        base_code = (vkc + 32_u16).to_u32
      when Windows::VK_LWIN
        base_code = KeyLeftSuper
      when Windows::VK_RWIN
        base_code = KeyRightSuper
      when Windows::VK_APPS
        base_code = KeyMenu
      when Windows::VK_NUMPAD0..Windows::VK_NUMPAD9
        base_code = (vkc - Windows::VK_NUMPAD0).to_u32 + KeyKp0
      when Windows::VK_MULTIPLY
        base_code = KeyKpMultiply
      when Windows::VK_ADD
        base_code = KeyKpPlus
      when Windows::VK_SEPARATOR
        base_code = KeyKpComma
      when Windows::VK_SUBTRACT
        base_code = KeyKpMinus
      when Windows::VK_DECIMAL
        base_code = KeyKpDecimal
      when Windows::VK_DIVIDE
        base_code = KeyKpDivide
      when Windows::VK_F1..Windows::VK_F24
        base_code = (vkc - Windows::VK_F1).to_u32 + KeyF1
      when Windows::VK_NUMLOCK
        base_code = KeyNumLock
      when Windows::VK_SCROLL
        base_code = KeyScrollLock
      when Windows::VK_LSHIFT
        base_code = KeyLeftShift
      when Windows::VK_RSHIFT
        base_code = KeyRightShift
      when Windows::VK_LCONTROL
        base_code = KeyLeftCtrl
      when Windows::VK_RCONTROL
        base_code = KeyRightCtrl
      when Windows::VK_LMENU
        base_code = KeyLeftAlt
      when Windows::VK_RMENU
        base_code = KeyRightAlt
      when Windows::VK_VOLUME_MUTE
        base_code = KeyMute
      when Windows::VK_VOLUME_DOWN
        base_code = KeyLowerVol
      when Windows::VK_VOLUME_UP
        base_code = KeyRaiseVol
      when Windows::VK_MEDIA_NEXT_TRACK
        base_code = KeyMediaNext
      when Windows::VK_MEDIA_PREV_TRACK
        base_code = KeyMediaPrev
      when Windows::VK_MEDIA_STOP
        base_code = KeyMediaStop
      when Windows::VK_MEDIA_PLAY_PAUSE
        base_code = KeyMediaPlayPause
      when Windows::VK_OEM_1
        base_code = ';'.ord.to_u32
      when Windows::VK_OEM_PLUS
        base_code = '+'.ord.to_u32
      when Windows::VK_OEM_COMMA
        base_code = ','.ord.to_u32
      when Windows::VK_OEM_MINUS
        base_code = '-'.ord.to_u32
      when Windows::VK_OEM_PERIOD
        base_code = '.'.ord.to_u32
      when Windows::VK_OEM_2
        base_code = '/'.ord.to_u32
      when Windows::VK_OEM_3
        base_code = '`'.ord.to_u32
      when Windows::VK_OEM_4
        base_code = '['.ord.to_u32
      when Windows::VK_OEM_5
        base_code = '\\'.ord.to_u32
      when Windows::VK_OEM_6
        base_code = ']'.ord.to_u32
      when Windows::VK_OEM_7
        base_code = '\''.ord.to_u32
      end

      # UTF-16 surrogate pair handling requires state and is unavailable here.
      if r.ord >= 0xD800 && r.ord <= 0xDFFF
        return nil
      end

      alt_gr = (cks & (Windows::LEFT_CTRL_PRESSED | Windows::RIGHT_ALT_PRESSED)) ==
               (Windows::LEFT_CTRL_PRESSED | Windows::RIGHT_ALT_PRESSED)

      text = ""
      key_code = base_code
      unless r.control?
        key_code = r.ord.to_u32
        if r.printable? && (cks == 0 || cks == Windows::SHIFT_PRESSED || cks == Windows::CAPSLOCK_ON || alt_gr)
          text = r.to_s
        end
      end

      key = Key.new(
        code: key_code,
        text: text,
        mod: translate_control_key_state(cks),
        base_code: base_code
      )
      key = ensure_key_case(key, cks)
      event = key_down ? KeyPressEvent.new(key).as(Event) : KeyReleaseEvent.new(key).as(Event)

      if repeat_count > 1
        repeated = Array(Event).new(repeat_count.to_i) { event }
        return MultiEvent.new(repeated)
      end

      event
    end

    private def ensure_key_case(key : Key, cks : UInt32) : Key
      return key if key.text.empty?

      has_shift = (cks & Windows::SHIFT_PRESSED) != 0
      has_caps = (cks & Windows::CAPSLOCK_ON) != 0
      if has_shift || has_caps
        if key.code.chr.lowercase?
          key.shifted_code = key.code.chr.upcase.ord.to_u32
          key.text = key.shifted_code.chr.to_s
        end
      else
        if key.code.chr.uppercase?
          key.shifted_code = key.code.chr.downcase.ord.to_u32
          key.text = key.shifted_code.chr.to_s
        end
      end

      key
    end

    private def translate_control_key_state(cks : UInt32) : KeyMod
      m = KeyMod::None
      if (cks & Windows::LEFT_CTRL_PRESSED) != 0 || (cks & Windows::RIGHT_CTRL_PRESSED) != 0
        m |= ModCtrl
      end
      if (cks & Windows::LEFT_ALT_PRESSED) != 0 || (cks & Windows::RIGHT_ALT_PRESSED) != 0
        m |= ModAlt
      end
      m |= ModShift if (cks & Windows::SHIFT_PRESSED) != 0
      m |= ModCapsLock if (cks & Windows::CAPSLOCK_ON) != 0
      m |= ModNumLock if (cks & Windows::NUMLOCK_ON) != 0
      m |= ModScrollLock if (cks & Windows::SCROLLLOCK_ON) != 0
      m
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

      # UTF-8 decoding
      # Decode first rune
      decoded = decode_rune(buf)
      unless decoded
        return {1, UnknownEvent.new(buf[0].chr.to_s)}
      end
      rune, rune_size = decoded

      if rune_size == 0
        return {1, UnknownEvent.new(buf[0].chr.to_s)}
      end

      # Get grapheme cluster using textseg
      # TextSegment provides grapheme cluster iteration
      # Limit scan to first 16 bytes (max reasonable grapheme cluster size)
      max_scan = buf.size > 16 ? 16 : buf.size
      # Create a string from the buffer slice, skipping invalid bytes
      str = String.new(buf[0, max_scan], "UTF-8", invalid: :skip)
      clusters = TextSegment.graphemes(str)
      cluster = clusters.first?
      if cluster.nil?
        return {rune_size, KeyPressEvent.new(code: rune.ord.to_u32, text: rune.to_s).as(Event)}
      end

      text = cluster.str
      cluster_bytes = cluster.bytes.size
      code = rune.ord.to_u32
      if cluster_bytes > rune_size
        # Multi-rune grapheme, use KeyExtended
        code = KeyExtended
      end

      {cluster_bytes, KeyPressEvent.new(code: code, text: text).as(Event)}
    end

    private def decode_rune(buf : Bytes) : {Char, Int32}?
      b = buf[0]
      if b < 0x80
        return {b.chr, 1}
      elsif b < 0xC2
        nil # invalid
      elsif b < 0xE0
        # 2-byte sequence
        if buf.size < 2 || (buf[1] & 0xC0) != 0x80
          return nil
        end
        codepoint = (((b & 0x1F).to_i32) << 6) | ((buf[1] & 0x3F).to_i32)
        # reject overlong
        if codepoint < 0x80
          return nil
        end
        return {codepoint.chr, 2}
      elsif b < 0xF0
        # 3-byte sequence
        if buf.size < 3 || (buf[1] & 0xC0) != 0x80 || (buf[2] & 0xC0) != 0x80
          return nil
        end
        codepoint = (((b & 0x0F).to_i32) << 12) |
                    (((buf[1] & 0x3F).to_i32) << 6) |
                    ((buf[2] & 0x3F).to_i32)
        # reject overlong
        if codepoint < 0x800
          return nil
        end
        # reject surrogate halves
        if codepoint >= 0xD800 && codepoint <= 0xDFFF
          return nil
        end
        return {codepoint.chr, 3}
      elsif b < 0xF5
        # 4-byte sequence
        if buf.size < 4 || (buf[1] & 0xC0) != 0x80 || (buf[2] & 0xC0) != 0x80 || (buf[3] & 0xC0) != 0x80
          return nil
        end
        codepoint = (((b & 0x07).to_i32) << 18) |
                    (((buf[1] & 0x3F).to_i32) << 12) |
                    (((buf[2] & 0x3F).to_i32) << 6) |
                    ((buf[3] & 0x3F).to_i32)
        # reject overlong
        if codepoint < 0x10000
          return nil
        end
        # reject codepoints above Unicode max
        if codepoint > 0x10FFFF
          return nil
        end
        return {codepoint.chr, 4}
      else
        nil
      end
    end

    # Parse X10-encoded mouse events; the simplest kind.
    # X10 mouse events look like: ESC [M Cb Cx Cy
    # See: http://www.xfree86.org/current/ctlseqs.html#Mouse%20Tracking

  end
end
