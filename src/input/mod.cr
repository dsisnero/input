module Input
  # KeyMod represents modifier keys.
  @[Flags]
  enum KeyMod : UInt32
    Shift      = 1 << 0
    Alt        = 1 << 1
    Ctrl       = 1 << 2
    Meta       = 1 << 3
    Hyper      = 1 << 4
    Super      = 1 << 5
    CapsLock   = 1 << 6
    NumLock    = 1 << 7
    ScrollLock = 1 << 8

    # Contains reports whether m contains the given modifiers.
    #
    # Example:
    #
    # m = KeyMod::Alt | KeyMod::Ctrl
    # m.contains(KeyMod::Ctrl) # true
    # m.contains(KeyMod::Alt | KeyMod::Ctrl) # true
    # m.contains(KeyMod::Alt | KeyMod::Ctrl | KeyMod::Shift) # false
    def contains(mods : KeyMod) : Bool
      includes?(mods)
    end
  end

  # Modifier key constants (aliases for convenience).
  ModShift      = KeyMod::Shift
  ModAlt        = KeyMod::Alt
  ModCtrl       = KeyMod::Ctrl
  ModMeta       = KeyMod::Meta
  ModHyper      = KeyMod::Hyper
  ModSuper      = KeyMod::Super
  ModCapsLock   = KeyMod::CapsLock
  ModNumLock    = KeyMod::NumLock
  ModScrollLock = KeyMod::ScrollLock
end
