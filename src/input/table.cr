require "ansi"
require "./key"
require "./parse"

module Input
  def self.build_keys_table(flags : Int32, term : String) : Hash(String, Key)
    nul = Key.new(mod: KeyMod::Ctrl, code: KeySpace) # ctrl+@ or ctrl+space
    if (flags & FlagCtrlAt) != 0
      nul = Key.new(mod: KeyMod::Ctrl, code: '@'.ord.to_u32)
    end

    tab = Key.new(code: KeyTab) # ctrl+i or tab
    if (flags & FlagCtrlI) != 0
      tab = Key.new(mod: KeyMod::Ctrl, code: 'i'.ord.to_u32)
    end

    enter = Key.new(code: KeyEnter) # ctrl+m or enter
    if (flags & FlagCtrlM) != 0
      enter = Key.new(mod: KeyMod::Ctrl, code: 'm'.ord.to_u32)
    end

    esc = Key.new(code: KeyEscape) # ctrl+[ or escape
    if (flags & FlagCtrlOpenBracket) != 0
      esc = Key.new(mod: KeyMod::Ctrl, code: '['.ord.to_u32)
    end

    del = Key.new(code: KeyBackspace)
    if (flags & FlagBackspace) != 0
      del = Key.new(code: KeyDelete)
    end

    find = Key.new(code: KeyHome)
    if (flags & FlagFind) != 0
      find = Key.new(code: KeyFind)
    end

    sel = Key.new(code: KeyEnd)
    if (flags & FlagSelect) != 0
      sel = Key.new(code: KeySelect)
    end

    # The following is a table of key sequences and their corresponding key
    # events based on the VT100/VT200 terminal specs.
    #
    # See: https://vt100.net/docs/vt100-ug/chapter3.html#S3.2
    # See: https://vt100.net/docs/vt220-rm/chapter3.html
    #
    # XXX: These keys may be overwritten by other options like XTerm or
    # Terminfo.
    table = Hash(String, Key).new
    table[String.new(Bytes[Ansi::C0::NUL])] = nul
    table[String.new(Bytes[Ansi::C0::SOH])] = Key.new(mod: KeyMod::Ctrl, code: 'a'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::STX])] = Key.new(mod: KeyMod::Ctrl, code: 'b'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::ETX])] = Key.new(mod: KeyMod::Ctrl, code: 'c'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::EOT])] = Key.new(mod: KeyMod::Ctrl, code: 'd'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::ENQ])] = Key.new(mod: KeyMod::Ctrl, code: 'e'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::ACK])] = Key.new(mod: KeyMod::Ctrl, code: 'f'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::BEL])] = Key.new(mod: KeyMod::Ctrl, code: 'g'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::BS])] = Key.new(mod: KeyMod::Ctrl, code: 'h'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::HT])] = tab
    table[String.new(Bytes[Ansi::C0::LF])] = Key.new(mod: KeyMod::Ctrl, code: 'j'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::VT])] = Key.new(mod: KeyMod::Ctrl, code: 'k'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::FF])] = Key.new(mod: KeyMod::Ctrl, code: 'l'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::CR])] = enter
    table[String.new(Bytes[Ansi::C0::SO])] = Key.new(mod: KeyMod::Ctrl, code: 'n'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::SI])] = Key.new(mod: KeyMod::Ctrl, code: 'o'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::DLE])] = Key.new(mod: KeyMod::Ctrl, code: 'p'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::DC1])] = Key.new(mod: KeyMod::Ctrl, code: 'q'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::DC2])] = Key.new(mod: KeyMod::Ctrl, code: 'r'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::DC3])] = Key.new(mod: KeyMod::Ctrl, code: 's'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::DC4])] = Key.new(mod: KeyMod::Ctrl, code: 't'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::NAK])] = Key.new(mod: KeyMod::Ctrl, code: 'u'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::SYN])] = Key.new(mod: KeyMod::Ctrl, code: 'v'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::ETB])] = Key.new(mod: KeyMod::Ctrl, code: 'w'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::CAN])] = Key.new(mod: KeyMod::Ctrl, code: 'x'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::EM])] = Key.new(mod: KeyMod::Ctrl, code: 'y'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::SUB])] = Key.new(mod: KeyMod::Ctrl, code: 'z'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::ESC])] = esc
    table[String.new(Bytes[Ansi::C0::FS])] = Key.new(mod: KeyMod::Ctrl, code: '\\'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::GS])] = Key.new(mod: KeyMod::Ctrl, code: ']'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::RS])] = Key.new(mod: KeyMod::Ctrl, code: '^'.ord.to_u32)
    table[String.new(Bytes[Ansi::C0::US])] = Key.new(mod: KeyMod::Ctrl, code: '_'.ord.to_u32)

    # Special keys in G0
    table[String.new(Bytes[Ansi::SP])] = Key.new(code: KeySpace, text: " ")
    table[String.new(Bytes[Ansi::DEL])] = del

    # Special keys
    table["\e[Z"] = Key.new(code: KeyTab, mod: KeyMod::Shift)

    table["\e[1~"] = find
    table["\e[2~"] = Key.new(code: KeyInsert)
    table["\e[3~"] = Key.new(code: KeyDelete)
    table["\e[4~"] = sel
    table["\e[5~"] = Key.new(code: KeyPgUp)
    table["\e[6~"] = Key.new(code: KeyPgDown)
    table["\e[7~"] = Key.new(code: KeyHome)
    table["\e[8~"] = Key.new(code: KeyEnd)

    # Normal mode
    table["\e[A"] = Key.new(code: KeyUp)
    table["\e[B"] = Key.new(code: KeyDown)
    table["\e[C"] = Key.new(code: KeyRight)
    table["\e[D"] = Key.new(code: KeyLeft)
    table["\e[E"] = Key.new(code: KeyBegin)
    table["\e[F"] = Key.new(code: KeyEnd)
    table["\e[H"] = Key.new(code: KeyHome)
    table["\e[P"] = Key.new(code: KeyF1)
    table["\e[Q"] = Key.new(code: KeyF2)
    table["\e[R"] = Key.new(code: KeyF3)
    table["\e[S"] = Key.new(code: KeyF4)

    # Application Cursor Key Mode (DECCKM)
    table["\eOA"] = Key.new(code: KeyUp)
    table["\eOB"] = Key.new(code: KeyDown)
    table["\eOC"] = Key.new(code: KeyRight)
    table["\eOD"] = Key.new(code: KeyLeft)
    table["\eOE"] = Key.new(code: KeyBegin)
    table["\eOF"] = Key.new(code: KeyEnd)
    table["\eOH"] = Key.new(code: KeyHome)
    table["\eOP"] = Key.new(code: KeyF1)
    table["\eOQ"] = Key.new(code: KeyF2)
    table["\eOR"] = Key.new(code: KeyF3)
    table["\eOS"] = Key.new(code: KeyF4)

    # Keypad Application Mode (DECKPAM)
    table["\eOM"] = Key.new(code: KeyKpEnter)
    table["\eOX"] = Key.new(code: KeyKpEqual)
    table["\eOj"] = Key.new(code: KeyKpMultiply)
    table["\eOk"] = Key.new(code: KeyKpPlus)
    table["\eOl"] = Key.new(code: KeyKpComma)
    table["\eOm"] = Key.new(code: KeyKpMinus)
    table["\eOn"] = Key.new(code: KeyKpDecimal)
    table["\eOo"] = Key.new(code: KeyKpDivide)
    table["\eOp"] = Key.new(code: KeyKp0)
    table["\eOq"] = Key.new(code: KeyKp1)
    table["\eOr"] = Key.new(code: KeyKp2)
    table["\eOs"] = Key.new(code: KeyKp3)
    table["\eOt"] = Key.new(code: KeyKp4)
    table["\eOu"] = Key.new(code: KeyKp5)
    table["\eOv"] = Key.new(code: KeyKp6)
    table["\eOw"] = Key.new(code: KeyKp7)
    table["\eOx"] = Key.new(code: KeyKp8)
    table["\eOy"] = Key.new(code: KeyKp9)

    # Function keys
    table["\e[11~"] = Key.new(code: KeyF1)
    table["\e[12~"] = Key.new(code: KeyF2)
    table["\e[13~"] = Key.new(code: KeyF3)
    table["\e[14~"] = Key.new(code: KeyF4)
    table["\e[15~"] = Key.new(code: KeyF5)
    table["\e[17~"] = Key.new(code: KeyF6)
    table["\e[18~"] = Key.new(code: KeyF7)
    table["\e[19~"] = Key.new(code: KeyF8)
    table["\e[20~"] = Key.new(code: KeyF9)
    table["\e[21~"] = Key.new(code: KeyF10)
    table["\e[23~"] = Key.new(code: KeyF11)
    table["\e[24~"] = Key.new(code: KeyF12)
    table["\e[25~"] = Key.new(code: KeyF13)
    table["\e[26~"] = Key.new(code: KeyF14)
    table["\e[28~"] = Key.new(code: KeyF15)
    table["\e[29~"] = Key.new(code: KeyF16)
    table["\e[31~"] = Key.new(code: KeyF17)
    table["\e[32~"] = Key.new(code: KeyF18)
    table["\e[33~"] = Key.new(code: KeyF19)
    table["\e[34~"] = Key.new(code: KeyF20)

    # CSI ~ sequence keys
    csi_tilde_keys = Hash(String, Key).new
    csi_tilde_keys["1"] = find
    csi_tilde_keys["2"] = Key.new(code: KeyInsert)
    csi_tilde_keys["3"] = Key.new(code: KeyDelete)
    csi_tilde_keys["4"] = sel
    csi_tilde_keys["5"] = Key.new(code: KeyPgUp)
    csi_tilde_keys["6"] = Key.new(code: KeyPgDown)
    csi_tilde_keys["7"] = Key.new(code: KeyHome)
    csi_tilde_keys["8"] = Key.new(code: KeyEnd)
    # There are no 9 and 10 keys
    csi_tilde_keys["11"] = Key.new(code: KeyF1)
    csi_tilde_keys["12"] = Key.new(code: KeyF2)
    csi_tilde_keys["13"] = Key.new(code: KeyF3)
    csi_tilde_keys["14"] = Key.new(code: KeyF4)
    csi_tilde_keys["15"] = Key.new(code: KeyF5)
    csi_tilde_keys["17"] = Key.new(code: KeyF6)
    csi_tilde_keys["18"] = Key.new(code: KeyF7)
    csi_tilde_keys["19"] = Key.new(code: KeyF8)
    csi_tilde_keys["20"] = Key.new(code: KeyF9)
    csi_tilde_keys["21"] = Key.new(code: KeyF10)
    csi_tilde_keys["23"] = Key.new(code: KeyF11)
    csi_tilde_keys["24"] = Key.new(code: KeyF12)
    csi_tilde_keys["25"] = Key.new(code: KeyF13)
    csi_tilde_keys["26"] = Key.new(code: KeyF14)
    csi_tilde_keys["28"] = Key.new(code: KeyF15)
    csi_tilde_keys["29"] = Key.new(code: KeyF16)
    csi_tilde_keys["31"] = Key.new(code: KeyF17)
    csi_tilde_keys["32"] = Key.new(code: KeyF18)
    csi_tilde_keys["33"] = Key.new(code: KeyF19)
    csi_tilde_keys["34"] = Key.new(code: KeyF20)

    # URxvt keys
    # See https://manpages.ubuntu.com/manpages/trusty/man7/urxvt.7.html#key%20codes
    table["\e[a"] = Key.new(code: KeyUp, mod: KeyMod::Shift)
    table["\e[b"] = Key.new(code: KeyDown, mod: KeyMod::Shift)
    table["\e[c"] = Key.new(code: KeyRight, mod: KeyMod::Shift)
    table["\e[d"] = Key.new(code: KeyLeft, mod: KeyMod::Shift)
    table["\eOa"] = Key.new(code: KeyUp, mod: KeyMod::Ctrl)
    table["\eOb"] = Key.new(code: KeyDown, mod: KeyMod::Ctrl)
    table["\eOc"] = Key.new(code: KeyRight, mod: KeyMod::Ctrl)
    table["\eOd"] = Key.new(code: KeyLeft, mod: KeyMod::Ctrl)
    # TODO: invistigate if shift-ctrl arrow keys collide with DECCKM keys i.e.
    # "\eOA", "\eOB", "\eOC", "\eOD"

    # URxvt modifier CSI ~ keys
    csi_tilde_keys.each do |k, v|
      key = v
      # Normal (no modifier) already defined part of VT100/VT200
      # Shift modifier
      key.mod = KeyMod::Shift
      table["\e[" + k + "$"] = key
      # Ctrl modifier
      key.mod = KeyMod::Ctrl
      table["\e[" + k + "^"] = key
      # Shift-Ctrl modifier
      key.mod = KeyMod::Shift | KeyMod::Ctrl
      table["\e[" + k + "@"] = key
    end

    # URxvt F keys
    # Note: Shift + F1-F10 generates F11-F20.
    # This means Shift + F1 and Shift + F2 will generate F11 and F12, the same
    # applies to Ctrl + Shift F1 & F2.
    #
    # P.S. Don't like this? Blame URxvt, configure your terminal to use
    # different escapes like XTerm, or switch to a better terminal ¯\_(ツ)_/¯
    #
    # See https://manpages.ubuntu.com/manpages/trusty/man7/urxvt.7.html#key%20codes
    table["\e[23$"] = Key.new(code: KeyF11, mod: KeyMod::Shift)
    table["\e[24$"] = Key.new(code: KeyF12, mod: KeyMod::Shift)
    table["\e[25$"] = Key.new(code: KeyF13, mod: KeyMod::Shift)
    table["\e[26$"] = Key.new(code: KeyF14, mod: KeyMod::Shift)
    table["\e[28$"] = Key.new(code: KeyF15, mod: KeyMod::Shift)
    table["\e[29$"] = Key.new(code: KeyF16, mod: KeyMod::Shift)
    table["\e[31$"] = Key.new(code: KeyF17, mod: KeyMod::Shift)
    table["\e[32$"] = Key.new(code: KeyF18, mod: KeyMod::Shift)
    table["\e[33$"] = Key.new(code: KeyF19, mod: KeyMod::Shift)
    table["\e[34$"] = Key.new(code: KeyF20, mod: KeyMod::Shift)
    table["\e[11^"] = Key.new(code: KeyF1, mod: KeyMod::Ctrl)
    table["\e[12^"] = Key.new(code: KeyF2, mod: KeyMod::Ctrl)
    table["\e[13^"] = Key.new(code: KeyF3, mod: KeyMod::Ctrl)
    table["\e[14^"] = Key.new(code: KeyF4, mod: KeyMod::Ctrl)
    table["\e[15^"] = Key.new(code: KeyF5, mod: KeyMod::Ctrl)
    table["\e[17^"] = Key.new(code: KeyF6, mod: KeyMod::Ctrl)
    table["\e[18^"] = Key.new(code: KeyF7, mod: KeyMod::Ctrl)
    table["\e[19^"] = Key.new(code: KeyF8, mod: KeyMod::Ctrl)
    table["\e[20^"] = Key.new(code: KeyF9, mod: KeyMod::Ctrl)
    table["\e[21^"] = Key.new(code: KeyF10, mod: KeyMod::Ctrl)
    table["\e[23^"] = Key.new(code: KeyF11, mod: KeyMod::Ctrl)
    table["\e[24^"] = Key.new(code: KeyF12, mod: KeyMod::Ctrl)
    table["\e[25^"] = Key.new(code: KeyF13, mod: KeyMod::Ctrl)
    table["\e[26^"] = Key.new(code: KeyF14, mod: KeyMod::Ctrl)
    table["\e[28^"] = Key.new(code: KeyF15, mod: KeyMod::Ctrl)
    table["\e[29^"] = Key.new(code: KeyF16, mod: KeyMod::Ctrl)
    table["\e[31^"] = Key.new(code: KeyF17, mod: KeyMod::Ctrl)
    table["\e[32^"] = Key.new(code: KeyF18, mod: KeyMod::Ctrl)
    table["\e[33^"] = Key.new(code: KeyF19, mod: KeyMod::Ctrl)
    table["\e[34^"] = Key.new(code: KeyF20, mod: KeyMod::Ctrl)
    table["\e[23@"] = Key.new(code: KeyF11, mod: KeyMod::Shift | KeyMod::Ctrl)
    table["\e[24@"] = Key.new(code: KeyF12, mod: KeyMod::Shift | KeyMod::Ctrl)
    table["\e[25@"] = Key.new(code: KeyF13, mod: KeyMod::Shift | KeyMod::Ctrl)
    table["\e[26@"] = Key.new(code: KeyF14, mod: KeyMod::Shift | KeyMod::Ctrl)
    table["\e[28@"] = Key.new(code: KeyF15, mod: KeyMod::Shift | KeyMod::Ctrl)
    table["\e[29@"] = Key.new(code: KeyF16, mod: KeyMod::Shift | KeyMod::Ctrl)
    table["\e[31@"] = Key.new(code: KeyF17, mod: KeyMod::Shift | KeyMod::Ctrl)
    table["\e[32@"] = Key.new(code: KeyF18, mod: KeyMod::Shift | KeyMod::Ctrl)
    table["\e[33@"] = Key.new(code: KeyF19, mod: KeyMod::Shift | KeyMod::Ctrl)
    table["\e[34@"] = Key.new(code: KeyF20, mod: KeyMod::Shift | KeyMod::Ctrl)

    # Register Alt + <key> combinations
    # XXX: this must come after URxvt but before XTerm keys to register URxvt
    # keys with alt modifier
    tmap = Hash(String, Key).new
    table.each do |seq, key|
      key = key.dup
      key.mod |= KeyMod::Alt
      key.text = "" # Clear runes
      tmap["\e" + seq] = key
    end
    table.merge!(tmap)

    # XTerm modifiers
    # These are offset by 1 to be compatible with our Mod type.
    # See https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-PC-Style-Function-Keys
    modifiers = [
      KeyMod::Shift,                                             # 1
      KeyMod::Alt,                                               # 2
      KeyMod::Shift | KeyMod::Alt,                               # 3
      KeyMod::Ctrl,                                              # 4
      KeyMod::Shift | KeyMod::Ctrl,                              # 5
      KeyMod::Alt | KeyMod::Ctrl,                                # 6
      KeyMod::Shift | KeyMod::Alt | KeyMod::Ctrl,                # 7
      KeyMod::Meta,                                              # 8
      KeyMod::Meta | KeyMod::Shift,                              # 9
      KeyMod::Meta | KeyMod::Alt,                                # 10
      KeyMod::Meta | KeyMod::Shift | KeyMod::Alt,                # 11
      KeyMod::Meta | KeyMod::Ctrl,                               # 12
      KeyMod::Meta | KeyMod::Shift | KeyMod::Ctrl,               # 13
      KeyMod::Meta | KeyMod::Alt | KeyMod::Ctrl,                 # 14
      KeyMod::Meta | KeyMod::Shift | KeyMod::Alt | KeyMod::Ctrl, # 15
    ]

    # SS3 keypad function keys
    ss3_func_keys = Hash(String, Key).new
    ss3_func_keys["M"] = Key.new(code: KeyKpEnter)
    ss3_func_keys["X"] = Key.new(code: KeyKpEqual)
    ss3_func_keys["j"] = Key.new(code: KeyKpMultiply)
    ss3_func_keys["k"] = Key.new(code: KeyKpPlus)
    ss3_func_keys["l"] = Key.new(code: KeyKpComma)
    ss3_func_keys["m"] = Key.new(code: KeyKpMinus)
    ss3_func_keys["n"] = Key.new(code: KeyKpDecimal)
    ss3_func_keys["o"] = Key.new(code: KeyKpDivide)
    ss3_func_keys["p"] = Key.new(code: KeyKp0)
    ss3_func_keys["q"] = Key.new(code: KeyKp1)
    ss3_func_keys["r"] = Key.new(code: KeyKp2)
    ss3_func_keys["s"] = Key.new(code: KeyKp3)
    ss3_func_keys["t"] = Key.new(code: KeyKp4)
    ss3_func_keys["u"] = Key.new(code: KeyKp5)
    ss3_func_keys["v"] = Key.new(code: KeyKp6)
    ss3_func_keys["w"] = Key.new(code: KeyKp7)
    ss3_func_keys["x"] = Key.new(code: KeyKp8)
    ss3_func_keys["y"] = Key.new(code: KeyKp9)

    # XTerm keys
    csi_func_keys = Hash(String, Key).new
    csi_func_keys["A"] = Key.new(code: KeyUp)
    csi_func_keys["B"] = Key.new(code: KeyDown)
    csi_func_keys["C"] = Key.new(code: KeyRight)
    csi_func_keys["D"] = Key.new(code: KeyLeft)
    csi_func_keys["E"] = Key.new(code: KeyBegin)
    csi_func_keys["F"] = Key.new(code: KeyEnd)
    csi_func_keys["H"] = Key.new(code: KeyHome)
    csi_func_keys["P"] = Key.new(code: KeyF1)
    csi_func_keys["Q"] = Key.new(code: KeyF2)
    csi_func_keys["R"] = Key.new(code: KeyF3)
    csi_func_keys["S"] = Key.new(code: KeyF4)

    # CSI 27 ; <modifier> ; <code> ~ keys defined in XTerm modifyOtherKeys
    modify_other_keys = Hash(Int32, Key).new
    modify_other_keys[Ansi::C0::BS] = Key.new(code: KeyBackspace)
    modify_other_keys[Ansi::C0::HT] = Key.new(code: KeyTab)
    modify_other_keys[Ansi::C0::CR] = Key.new(code: KeyEnter)
    modify_other_keys[Ansi::C0::ESC] = Key.new(code: KeyEscape)
    modify_other_keys[Ansi::DEL] = Key.new(code: KeyBackspace)

    modifiers.each do |m|
      # XTerm modifier offset +1
      xterm_mod = (m.value + 1).to_s

      #  CSI 1 ; <modifier> <func>
      csi_func_keys.each do |k, v|
        # Functions always have a leading 1 param
        seq = "\e[1;" + xterm_mod + k
        key = v.dup
        key.mod = m
        table[seq] = key
      end
      # SS3 <modifier> <func>
      ss3_func_keys.each do |k, v|
        seq = "\eO" + xterm_mod + k
        key = v.dup
        key.mod = m
        table[seq] = key
      end
      #  CSI <number> ; <modifier> ~
      csi_tilde_keys.each do |k, v|
        seq = "\e[" + k + ";" + xterm_mod + "~"
        key = v.dup
        key.mod = m
        table[seq] = key
      end
      # CSI 27 ; <modifier> ; <code> ~
      modify_other_keys.each do |k, v|
        code = k.to_s
        seq = "\e[27;" + xterm_mod + ";" + code + "~"
        key = v.dup
        key.mod = m
        table[seq] = key
      end
    end

    # Register terminfo keys
    # XXX: this might override keys already registered in table
    if (flags & FlagTerminfo) != 0
      titable = build_terminfo_keys(flags, term)
      table.merge!(titable)
    end

    table
  end

  def self.build_terminfo_keys(flags : Int32, term : String) : Hash(String, Key)
    table = Hash(String, Key).new
    ti = load_terminfo(term)
    return table if ti.nil?

    ti_table = default_terminfo_keys(flags)

    # Default keys
    ti.not_nil!.string_caps_short.each do |name, seq|
      next unless name.starts_with?("k")
      next if seq.empty?
      if k = ti_table[name]?
        table[seq] = k
      end
    end

    # Extended keys
    ti.not_nil!.ext_string_caps_short.each do |name, seq|
      next unless name.starts_with?("k")
      next if seq.empty?
      if k = ti_table[name]?
        table[seq] = k
      end
    end

    table
  end

  def self.default_terminfo_keys(flags : Int32) : Hash(String, Key)
    keys = Hash(String, Key).new
    keys["kcuu1"] = Key.new(code: KeyUp)
    keys["kUP"] = Key.new(code: KeyUp, mod: ModShift)
    keys["kUP3"] = Key.new(code: KeyUp, mod: ModAlt)
    keys["kUP4"] = Key.new(code: KeyUp, mod: ModShift | ModAlt)
    keys["kUP5"] = Key.new(code: KeyUp, mod: ModCtrl)
    keys["kUP6"] = Key.new(code: KeyUp, mod: ModShift | ModCtrl)
    keys["kUP7"] = Key.new(code: KeyUp, mod: ModAlt | ModCtrl)
    keys["kUP8"] = Key.new(code: KeyUp, mod: ModShift | ModAlt | ModCtrl)
    keys["kcud1"] = Key.new(code: KeyDown)
    keys["kDN"] = Key.new(code: KeyDown, mod: ModShift)
    keys["kDN3"] = Key.new(code: KeyDown, mod: ModAlt)
    keys["kDN4"] = Key.new(code: KeyDown, mod: ModShift | ModAlt)
    keys["kDN5"] = Key.new(code: KeyDown, mod: ModCtrl)
    keys["kDN7"] = Key.new(code: KeyDown, mod: ModAlt | ModCtrl)
    keys["kDN6"] = Key.new(code: KeyDown, mod: ModShift | ModCtrl)
    keys["kDN8"] = Key.new(code: KeyDown, mod: ModShift | ModAlt | ModCtrl)
    keys["kcub1"] = Key.new(code: KeyLeft)
    keys["kLFT"] = Key.new(code: KeyLeft, mod: ModShift)
    keys["kLFT3"] = Key.new(code: KeyLeft, mod: ModAlt)
    keys["kLFT4"] = Key.new(code: KeyLeft, mod: ModShift | ModAlt)
    keys["kLFT5"] = Key.new(code: KeyLeft, mod: ModCtrl)
    keys["kLFT6"] = Key.new(code: KeyLeft, mod: ModShift | ModCtrl)
    keys["kLFT7"] = Key.new(code: KeyLeft, mod: ModAlt | ModCtrl)
    keys["kLFT8"] = Key.new(code: KeyLeft, mod: ModShift | ModAlt | ModCtrl)
    keys["kcuf1"] = Key.new(code: KeyRight)
    keys["kRIT"] = Key.new(code: KeyRight, mod: ModShift)
    keys["kRIT3"] = Key.new(code: KeyRight, mod: ModAlt)
    keys["kRIT4"] = Key.new(code: KeyRight, mod: ModShift | ModAlt)
    keys["kRIT5"] = Key.new(code: KeyRight, mod: ModCtrl)
    keys["kRIT6"] = Key.new(code: KeyRight, mod: ModShift | ModCtrl)
    keys["kRIT7"] = Key.new(code: KeyRight, mod: ModAlt | ModCtrl)
    keys["kRIT8"] = Key.new(code: KeyRight, mod: ModShift | ModAlt | ModCtrl)
    keys["kich1"] = Key.new(code: KeyInsert)
    keys["kIC"] = Key.new(code: KeyInsert, mod: ModShift)
    keys["kIC3"] = Key.new(code: KeyInsert, mod: ModAlt)
    keys["kIC4"] = Key.new(code: KeyInsert, mod: ModShift | ModAlt)
    keys["kIC5"] = Key.new(code: KeyInsert, mod: ModCtrl)
    keys["kIC6"] = Key.new(code: KeyInsert, mod: ModShift | ModCtrl)
    keys["kIC7"] = Key.new(code: KeyInsert, mod: ModAlt | ModCtrl)
    keys["kIC8"] = Key.new(code: KeyInsert, mod: ModShift | ModAlt | ModCtrl)
    keys["kdch1"] = Key.new(code: KeyDelete)
    keys["kDC"] = Key.new(code: KeyDelete, mod: ModShift)
    keys["kDC3"] = Key.new(code: KeyDelete, mod: ModAlt)
    keys["kDC4"] = Key.new(code: KeyDelete, mod: ModShift | ModAlt)
    keys["kDC5"] = Key.new(code: KeyDelete, mod: ModCtrl)
    keys["kDC6"] = Key.new(code: KeyDelete, mod: ModShift | ModCtrl)
    keys["kDC7"] = Key.new(code: KeyDelete, mod: ModAlt | ModCtrl)
    keys["kDC8"] = Key.new(code: KeyDelete, mod: ModShift | ModAlt | ModCtrl)
    keys["khome"] = Key.new(code: KeyHome)
    keys["kHOM"] = Key.new(code: KeyHome, mod: ModShift)
    keys["kHOM3"] = Key.new(code: KeyHome, mod: ModAlt)
    keys["kHOM4"] = Key.new(code: KeyHome, mod: ModShift | ModAlt)
    keys["kHOM5"] = Key.new(code: KeyHome, mod: ModCtrl)
    keys["kHOM6"] = Key.new(code: KeyHome, mod: ModShift | ModCtrl)
    keys["kHOM7"] = Key.new(code: KeyHome, mod: ModAlt | ModCtrl)
    keys["kHOM8"] = Key.new(code: KeyHome, mod: ModShift | ModAlt | ModCtrl)
    keys["kend"] = Key.new(code: KeyEnd)
    keys["kEND"] = Key.new(code: KeyEnd, mod: ModShift)
    keys["kEND3"] = Key.new(code: KeyEnd, mod: ModAlt)
    keys["kEND4"] = Key.new(code: KeyEnd, mod: ModShift | ModAlt)
    keys["kEND5"] = Key.new(code: KeyEnd, mod: ModCtrl)
    keys["kEND6"] = Key.new(code: KeyEnd, mod: ModShift | ModCtrl)
    keys["kEND7"] = Key.new(code: KeyEnd, mod: ModAlt | ModCtrl)
    keys["kEND8"] = Key.new(code: KeyEnd, mod: ModShift | ModAlt | ModCtrl)
    keys["kpp"] = Key.new(code: KeyPgUp)
    keys["kprv"] = Key.new(code: KeyPgUp)
    keys["kPRV"] = Key.new(code: KeyPgUp, mod: ModShift)
    keys["kPRV3"] = Key.new(code: KeyPgUp, mod: ModAlt)
    keys["kPRV4"] = Key.new(code: KeyPgUp, mod: ModShift | ModAlt)
    keys["kPRV5"] = Key.new(code: KeyPgUp, mod: ModCtrl)
    keys["kPRV6"] = Key.new(code: KeyPgUp, mod: ModShift | ModCtrl)
    keys["kPRV7"] = Key.new(code: KeyPgUp, mod: ModAlt | ModCtrl)
    keys["kPRV8"] = Key.new(code: KeyPgUp, mod: ModShift | ModAlt | ModCtrl)
    keys["knp"] = Key.new(code: KeyPgDown)
    keys["knxt"] = Key.new(code: KeyPgDown)
    keys["kNXT"] = Key.new(code: KeyPgDown, mod: ModShift)
    keys["kNXT3"] = Key.new(code: KeyPgDown, mod: ModAlt)
    keys["kNXT4"] = Key.new(code: KeyPgDown, mod: ModShift | ModAlt)
    keys["kNXT5"] = Key.new(code: KeyPgDown, mod: ModCtrl)
    keys["kNXT6"] = Key.new(code: KeyPgDown, mod: ModShift | ModCtrl)
    keys["kNXT7"] = Key.new(code: KeyPgDown, mod: ModAlt | ModCtrl)
    keys["kNXT8"] = Key.new(code: KeyPgDown, mod: ModShift | ModAlt | ModCtrl)
    keys["kbs"] = Key.new(code: KeyBackspace)
    keys["kcbt"] = Key.new(code: KeyTab, mod: ModShift)
    # Function keys
    keys["kf1"] = Key.new(code: KeyF1)
    keys["kf2"] = Key.new(code: KeyF2)
    keys["kf3"] = Key.new(code: KeyF3)
    keys["kf4"] = Key.new(code: KeyF4)
    keys["kf5"] = Key.new(code: KeyF5)
    keys["kf6"] = Key.new(code: KeyF6)
    keys["kf7"] = Key.new(code: KeyF7)
    keys["kf8"] = Key.new(code: KeyF8)
    keys["kf9"] = Key.new(code: KeyF9)
    keys["kf10"] = Key.new(code: KeyF10)
    keys["kf11"] = Key.new(code: KeyF11)
    keys["kf12"] = Key.new(code: KeyF12)
    keys["kf13"] = Key.new(code: KeyF1, mod: ModShift)
    keys["kf14"] = Key.new(code: KeyF2, mod: ModShift)
    keys["kf15"] = Key.new(code: KeyF3, mod: ModShift)
    keys["kf16"] = Key.new(code: KeyF4, mod: ModShift)
    keys["kf17"] = Key.new(code: KeyF5, mod: ModShift)
    keys["kf18"] = Key.new(code: KeyF6, mod: ModShift)
    keys["kf19"] = Key.new(code: KeyF7, mod: ModShift)
    keys["kf20"] = Key.new(code: KeyF8, mod: ModShift)
    keys["kf21"] = Key.new(code: KeyF9, mod: ModShift)
    keys["kf22"] = Key.new(code: KeyF10, mod: ModShift)
    keys["kf23"] = Key.new(code: KeyF11, mod: ModShift)
    keys["kf24"] = Key.new(code: KeyF12, mod: ModShift)
    keys["kf25"] = Key.new(code: KeyF1, mod: ModCtrl)
    keys["kf26"] = Key.new(code: KeyF2, mod: ModCtrl)
    keys["kf27"] = Key.new(code: KeyF3, mod: ModCtrl)
    keys["kf28"] = Key.new(code: KeyF4, mod: ModCtrl)
    keys["kf29"] = Key.new(code: KeyF5, mod: ModCtrl)
    keys["kf30"] = Key.new(code: KeyF6, mod: ModCtrl)
    keys["kf31"] = Key.new(code: KeyF7, mod: ModCtrl)
    keys["kf32"] = Key.new(code: KeyF8, mod: ModCtrl)
    keys["kf33"] = Key.new(code: KeyF9, mod: ModCtrl)
    keys["kf34"] = Key.new(code: KeyF10, mod: ModCtrl)
    keys["kf35"] = Key.new(code: KeyF11, mod: ModCtrl)
    keys["kf36"] = Key.new(code: KeyF12, mod: ModCtrl)
    keys["kf37"] = Key.new(code: KeyF1, mod: ModShift | ModCtrl)
    keys["kf38"] = Key.new(code: KeyF2, mod: ModShift | ModCtrl)
    keys["kf39"] = Key.new(code: KeyF3, mod: ModShift | ModCtrl)
    keys["kf40"] = Key.new(code: KeyF4, mod: ModShift | ModCtrl)
    keys["kf41"] = Key.new(code: KeyF5, mod: ModShift | ModCtrl)
    keys["kf42"] = Key.new(code: KeyF6, mod: ModShift | ModCtrl)
    keys["kf43"] = Key.new(code: KeyF7, mod: ModShift | ModCtrl)
    keys["kf44"] = Key.new(code: KeyF8, mod: ModShift | ModCtrl)
    keys["kf45"] = Key.new(code: KeyF9, mod: ModShift | ModCtrl)
    keys["kf46"] = Key.new(code: KeyF10, mod: ModShift | ModCtrl)
    keys["kf47"] = Key.new(code: KeyF11, mod: ModShift | ModCtrl)
    keys["kf48"] = Key.new(code: KeyF12, mod: ModShift | ModCtrl)
    keys["kf49"] = Key.new(code: KeyF1, mod: ModAlt)
    keys["kf50"] = Key.new(code: KeyF2, mod: ModAlt)
    keys["kf51"] = Key.new(code: KeyF3, mod: ModAlt)
    keys["kf52"] = Key.new(code: KeyF4, mod: ModAlt)
    keys["kf53"] = Key.new(code: KeyF5, mod: ModAlt)
    keys["kf54"] = Key.new(code: KeyF6, mod: ModAlt)
    keys["kf55"] = Key.new(code: KeyF7, mod: ModAlt)
    keys["kf56"] = Key.new(code: KeyF8, mod: ModAlt)
    keys["kf57"] = Key.new(code: KeyF9, mod: ModAlt)
    keys["kf58"] = Key.new(code: KeyF10, mod: ModAlt)
    keys["kf59"] = Key.new(code: KeyF11, mod: ModAlt)
    keys["kf60"] = Key.new(code: KeyF12, mod: ModAlt)
    keys["kf61"] = Key.new(code: KeyF1, mod: ModShift | ModAlt)
    keys["kf62"] = Key.new(code: KeyF2, mod: ModShift | ModAlt)
    keys["kf63"] = Key.new(code: KeyF3, mod: ModShift | ModAlt)

    # Preserve F keys from F13 to F63 instead of using them for F-keys
    # modifiers.
    if (flags & FlagFKeys) != 0
      keys["kf13"] = Key.new(code: KeyF13)
      keys["kf14"] = Key.new(code: KeyF14)
      keys["kf15"] = Key.new(code: KeyF15)
      keys["kf16"] = Key.new(code: KeyF16)
      keys["kf17"] = Key.new(code: KeyF17)
      keys["kf18"] = Key.new(code: KeyF18)
      keys["kf19"] = Key.new(code: KeyF19)
      keys["kf20"] = Key.new(code: KeyF20)
      keys["kf21"] = Key.new(code: KeyF21)
      keys["kf22"] = Key.new(code: KeyF22)
      keys["kf23"] = Key.new(code: KeyF23)
      keys["kf24"] = Key.new(code: KeyF24)
      keys["kf25"] = Key.new(code: KeyF25)
      keys["kf26"] = Key.new(code: KeyF26)
      keys["kf27"] = Key.new(code: KeyF27)
      keys["kf28"] = Key.new(code: KeyF28)
      keys["kf29"] = Key.new(code: KeyF29)
      keys["kf30"] = Key.new(code: KeyF30)
      keys["kf31"] = Key.new(code: KeyF31)
      keys["kf32"] = Key.new(code: KeyF32)
      keys["kf33"] = Key.new(code: KeyF33)
      keys["kf34"] = Key.new(code: KeyF34)
      keys["kf35"] = Key.new(code: KeyF35)
      keys["kf36"] = Key.new(code: KeyF36)
      keys["kf37"] = Key.new(code: KeyF37)
      keys["kf38"] = Key.new(code: KeyF38)
      keys["kf39"] = Key.new(code: KeyF39)
      keys["kf40"] = Key.new(code: KeyF40)
      keys["kf41"] = Key.new(code: KeyF41)
      keys["kf42"] = Key.new(code: KeyF42)
      keys["kf43"] = Key.new(code: KeyF43)
      keys["kf44"] = Key.new(code: KeyF44)
      keys["kf45"] = Key.new(code: KeyF45)
      keys["kf46"] = Key.new(code: KeyF46)
      keys["kf47"] = Key.new(code: KeyF47)
      keys["kf48"] = Key.new(code: KeyF48)
      keys["kf49"] = Key.new(code: KeyF49)
      keys["kf50"] = Key.new(code: KeyF50)
      keys["kf51"] = Key.new(code: KeyF51)
      keys["kf52"] = Key.new(code: KeyF52)
      keys["kf53"] = Key.new(code: KeyF53)
      keys["kf54"] = Key.new(code: KeyF54)
      keys["kf55"] = Key.new(code: KeyF55)
      keys["kf56"] = Key.new(code: KeyF56)
      keys["kf57"] = Key.new(code: KeyF57)
      keys["kf58"] = Key.new(code: KeyF58)
      keys["kf59"] = Key.new(code: KeyF59)
      keys["kf60"] = Key.new(code: KeyF60)
      keys["kf61"] = Key.new(code: KeyF61)
      keys["kf62"] = Key.new(code: KeyF62)
      keys["kf63"] = Key.new(code: KeyF63)
    end

    keys
  end
end
