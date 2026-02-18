module Input
  def self.parse_xterm_modify_other_keys(params : Ansi::Params) : Event
    # XTerm modify other keys starts with ESC [ 27 ; <modifier> ; <code> ~
    xmod, _, _ = params.param(1, 1)
    xrune, _, _ = params.param(2, 1)
    mod = KeyMod.new((xmod - 1).to_u32)
    r = xrune.chr

    case r.ord
    when Ansi::BS
      return KeyPressEvent.new(mod: mod, code: KeyBackspace)
    when Ansi::HT
      return KeyPressEvent.new(mod: mod, code: KeyTab)
    when Ansi::CR
      return KeyPressEvent.new(mod: mod, code: KeyEnter)
    when Ansi::ESC
      return KeyPressEvent.new(mod: mod, code: KeyEscape)
    when Ansi::DEL
      return KeyPressEvent.new(mod: mod, code: KeyBackspace)
    end

    # CSI 27 ; <modifier> ; <code> ~ keys defined in XTerm modifyOtherKeys
    k = KeyPressEvent.new(code: r.ord.to_u32, mod: mod)
    if k.key.mod <= ModShift
      k.key.text = r.to_s
    end
    k
  end
end
