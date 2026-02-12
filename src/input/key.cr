require "ansi"

module Input
  # KeyExtended is a special key code used to signify that a key event
  # contains multiple runes.
  KeyExtended = Char::MAX_CODEPOINT + 1

  # Special key symbols.

  # Special keys.
  KeyUp     = KeyExtended + 1
  KeyDown   = KeyExtended + 2
  KeyRight  = KeyExtended + 3
  KeyLeft   = KeyExtended + 4
  KeyBegin  = KeyExtended + 5
  KeyFind   = KeyExtended + 6
  KeyInsert = KeyExtended + 7
  KeyDelete = KeyExtended + 8
  KeySelect = KeyExtended + 9
  KeyPgUp   = KeyExtended + 10
  KeyPgDown = KeyExtended + 11
  KeyHome   = KeyExtended + 12
  KeyEnd    = KeyExtended + 13

  # Keypad keys.
  KeyKpEnter    = KeyExtended + 14
  KeyKpEqual    = KeyExtended + 15
  KeyKpMultiply = KeyExtended + 16
  KeyKpPlus     = KeyExtended + 17
  KeyKpComma    = KeyExtended + 18
  KeyKpMinus    = KeyExtended + 19
  KeyKpDecimal  = KeyExtended + 20
  KeyKpDivide   = KeyExtended + 21
  KeyKp0        = KeyExtended + 22
  KeyKp1        = KeyExtended + 23
  KeyKp2        = KeyExtended + 24
  KeyKp3        = KeyExtended + 25
  KeyKp4        = KeyExtended + 26
  KeyKp5        = KeyExtended + 27
  KeyKp6        = KeyExtended + 28
  KeyKp7        = KeyExtended + 29
  KeyKp8        = KeyExtended + 30
  KeyKp9        = KeyExtended + 31

  # The following are keys defined in the Kitty keyboard protocol.
  # TODO: Investigate the names of these keys.
  KeyKpSep    = KeyExtended + 32
  KeyKpUp     = KeyExtended + 33
  KeyKpDown   = KeyExtended + 34
  KeyKpLeft   = KeyExtended + 35
  KeyKpRight  = KeyExtended + 36
  KeyKpPgUp   = KeyExtended + 37
  KeyKpPgDown = KeyExtended + 38
  KeyKpHome   = KeyExtended + 39
  KeyKpEnd    = KeyExtended + 40
  KeyKpInsert = KeyExtended + 41
  KeyKpDelete = KeyExtended + 42
  KeyKpBegin  = KeyExtended + 43

  # Function keys.
  KeyF1  = KeyExtended + 44
  KeyF2  = KeyExtended + 45
  KeyF3  = KeyExtended + 46
  KeyF4  = KeyExtended + 47
  KeyF5  = KeyExtended + 48
  KeyF6  = KeyExtended + 49
  KeyF7  = KeyExtended + 50
  KeyF8  = KeyExtended + 51
  KeyF9  = KeyExtended + 52
  KeyF10 = KeyExtended + 53
  KeyF11 = KeyExtended + 54
  KeyF12 = KeyExtended + 55
  KeyF13 = KeyExtended + 56
  KeyF14 = KeyExtended + 57
  KeyF15 = KeyExtended + 58
  KeyF16 = KeyExtended + 59
  KeyF17 = KeyExtended + 60
  KeyF18 = KeyExtended + 61
  KeyF19 = KeyExtended + 62
  KeyF20 = KeyExtended + 63
  KeyF21 = KeyExtended + 64
  KeyF22 = KeyExtended + 65
  KeyF23 = KeyExtended + 66
  KeyF24 = KeyExtended + 67
  KeyF25 = KeyExtended + 68
  KeyF26 = KeyExtended + 69
  KeyF27 = KeyExtended + 70
  KeyF28 = KeyExtended + 71
  KeyF29 = KeyExtended + 72
  KeyF30 = KeyExtended + 73
  KeyF31 = KeyExtended + 74
  KeyF32 = KeyExtended + 75
  KeyF33 = KeyExtended + 76
  KeyF34 = KeyExtended + 77
  KeyF35 = KeyExtended + 78
  KeyF36 = KeyExtended + 79
  KeyF37 = KeyExtended + 80
  KeyF38 = KeyExtended + 81
  KeyF39 = KeyExtended + 82
  KeyF40 = KeyExtended + 83
  KeyF41 = KeyExtended + 84
  KeyF42 = KeyExtended + 85
  KeyF43 = KeyExtended + 86
  KeyF44 = KeyExtended + 87
  KeyF45 = KeyExtended + 88
  KeyF46 = KeyExtended + 89
  KeyF47 = KeyExtended + 90
  KeyF48 = KeyExtended + 91
  KeyF49 = KeyExtended + 92
  KeyF50 = KeyExtended + 93
  KeyF51 = KeyExtended + 94
  KeyF52 = KeyExtended + 95
  KeyF53 = KeyExtended + 96
  KeyF54 = KeyExtended + 97
  KeyF55 = KeyExtended + 98
  KeyF56 = KeyExtended + 99
  KeyF57 = KeyExtended + 100
  KeyF58 = KeyExtended + 101
  KeyF59 = KeyExtended + 102
  KeyF60 = KeyExtended + 103
  KeyF61 = KeyExtended + 104
  KeyF62 = KeyExtended + 105
  KeyF63 = KeyExtended + 106

  # The following are keys defined in the Kitty keyboard protocol.
  # TODO: Investigate the names of these keys.
  KeyCapsLock    = KeyExtended + 107
  KeyScrollLock  = KeyExtended + 108
  KeyNumLock     = KeyExtended + 109
  KeyPrintScreen = KeyExtended + 110
  KeyPause       = KeyExtended + 111
  KeyMenu        = KeyExtended + 112

  KeyMediaPlay        = KeyExtended + 113
  KeyMediaPause       = KeyExtended + 114
  KeyMediaPlayPause   = KeyExtended + 115
  KeyMediaReverse     = KeyExtended + 116
  KeyMediaStop        = KeyExtended + 117
  KeyMediaFastForward = KeyExtended + 118
  KeyMediaRewind      = KeyExtended + 119
  KeyMediaNext        = KeyExtended + 120
  KeyMediaPrev        = KeyExtended + 121
  KeyMediaRecord      = KeyExtended + 122

  KeyLowerVol = KeyExtended + 123
  KeyRaiseVol = KeyExtended + 124
  KeyMute     = KeyExtended + 125

  KeyLeftShift      = KeyExtended + 126
  KeyLeftAlt        = KeyExtended + 127
  KeyLeftCtrl       = KeyExtended + 128
  KeyLeftSuper      = KeyExtended + 129
  KeyLeftHyper      = KeyExtended + 130
  KeyLeftMeta       = KeyExtended + 131
  KeyRightShift     = KeyExtended + 132
  KeyRightAlt       = KeyExtended + 133
  KeyRightCtrl      = KeyExtended + 134
  KeyRightSuper     = KeyExtended + 135
  KeyRightHyper     = KeyExtended + 136
  KeyRightMeta      = KeyExtended + 137
  KeyIsoLevel3Shift = KeyExtended + 138
  KeyIsoLevel5Shift = KeyExtended + 139

  # Special names in C0.
  KeyBackspace = Ansi::DEL.to_u32    # ansi.DEL
  KeyTab       = Ansi::C0::HT.to_u32 # ansi.HT
  KeyEnter     = Ansi::C0::CR.to_u32 # ansi.CR
  KeyReturn    = KeyEnter
  KeyEscape    = Ansi::C0::ESC.to_u32 # ansi.ESC
  KeyEsc       = KeyEscape

  # Special names in G0.
  KeySpace = Ansi::SP.to_u32 # ansi.SP

  # Key represents a Key press or release event. It contains information about
  # the Key pressed, like the runes, the type of Key, and the modifiers pressed.
  # There are a couple general patterns you could use to check for key presses
  # or releases:
  #
  # // Switch on the string representation of the key (shorter)
  # switch ev := ev.(type) {
  # case KeyPressEvent:
  #     switch ev.String() {
  #     case "enter":
  #         fmt.Println("you pressed enter!")
  #     case "a":
  #         fmt.Println("you pressed a!")
  #     }
  # }
  #
  # // Switch on the key type (more foolproof)
  # switch ev := ev.(type) {
  # case KeyEvent:
  #     // catch both KeyPressEvent and KeyReleaseEvent
  #     switch key := ev.Key(); key.Code {
  #     case KeyEnter:
  #         fmt.Println("you pressed enter!")
  #     default:
  #         switch key.Text {
  #         case "a":
  #             fmt.Println("you pressed a!")
  #         }
  #     }
  # }
  struct Key
    # Text contains the actual characters received. This usually the same as
    # Code. When Text is non-empty, it indicates that the key
    # pressed represents printable character(s).
    property text : String

    # Mod represents modifier keys, like ModCtrl, ModAlt, and so on.
    property mod : KeyMod

    # Code represents the key pressed. This is usually a special key like
    # KeyTab, KeyEnter, KeyF1, or a printable character like 'a'.
    property code : UInt32

    # ShiftedCode is the actual, shifted key pressed by the user. For example,
    # if the user presses shift+a, or caps lock is on, ShiftedCode will
    # be 'A' and Code will be 'a'.
    #
    # In the case of non-latin keyboards, like Arabic, ShiftedCode is the
    # unshifted key on the keyboard.
    #
    # This is only available with the Kitty Keyboard Protocol or the Windows
    # Console API.
    property shifted_code : UInt32

    # BaseCode is the key pressed according to the standard PC-101 key layout.
    # On international keyboards, this is the key that would be pressed if the
    # keyboard was set to US PC-101 layout.
    #
    # For example, if the user presses 'q' on a French AZERTY keyboard,
    # BaseCode will be 'q'.
    #
    # This is only available with the Kitty Keyboard Protocol or the Windows
    # Console API.
    property base_code : UInt32

    # IsRepeat indicates whether the key is being held down and sending events
    # repeatedly.
    #
    # This is only available with the Kitty Keyboard Protocol or the Windows
    # Console API.
    property? repeat : Bool

    def initialize(@text : String = "", @mod : KeyMod = KeyMod::None, @code : UInt32 = 0, @shifted_code : UInt32 = 0, @base_code : UInt32 = 0, @repeat : Bool = false)
    end

    # Returns the textual representation of the Key if there is
    # one, otherwise, it will fallback to Keystroke.
    #
    # For example, you'll always get "?" and instead of "shift+/" on a US ANSI
    # keyboard.
    def to_s : String
      if !@text.empty? && @text != " "
        @text
      else
        keystroke
      end
    end

    # Returns the keystroke representation of the Key. While less type
    # safe than looking at the individual fields, it will usually be more
    # convenient and readable to use this method when matching against keys.
    #
    # Note that modifier keys are always printed in the following order:
    #   - ctrl
    #   - alt
    #   - shift
    #   - meta
    #   - hyper
    #   - super
    #
    # For example, you'll always see "ctrl+shift+alt+a" and never
    # "shift+ctrl+alt+a".
    def keystroke : String
      String.build do |io|
        if @mod.contains(ModCtrl) && @code != KeyLeftCtrl && @code != KeyRightCtrl
          io << "ctrl+"
        end
        if @mod.contains(ModAlt) && @code != KeyLeftAlt && @code != KeyRightAlt
          io << "alt+"
        end
        if @mod.contains(ModShift) && @code != KeyLeftShift && @code != KeyRightShift
          io << "shift+"
        end
        if @mod.contains(ModMeta) && @code != KeyLeftMeta && @code != KeyRightMeta
          io << "meta+"
        end
        if @mod.contains(ModHyper) && @code != KeyLeftHyper && @code != KeyRightHyper
          io << "hyper+"
        end
        if @mod.contains(ModSuper) && @code != KeyLeftSuper && @code != KeyRightSuper
          io << "super+"
        end

        if kt = KEY_TYPE_STRING[@code]?
          io << kt
        else
          code = @code
          if @base_code != 0
            # If a BaseCode is present, use it to represent a key using the standard
            # PC-101 key layout.
            code = @base_code
          end

          case code
          when KeySpace
            # Space is the only invisible printable character.
            io << "space"
          when KeyExtended
            # Write the actual text of the key when the key contains multiple
            # runes.
            io << @text
          else
            io << code.chr
          end
        end
      end
    end
  end

  # KeyEvent represents a key event. This can be either a key press or a key
  # release event.
  module KeyEvent
    abstract def to_s : String
    abstract def key : Key
    abstract def keystroke : String
  end

  # KeyPressEvent represents a key press event.
  class KeyPressEvent < Event
    include KeyEvent

    getter key : Key

    def initialize(@key : Key)
    end

    def initialize(text : String = "", mod : KeyMod = KeyMod::None, code : UInt32 = 0, shifted_code : UInt32 = 0, base_code : UInt32 = 0, is_repeat : Bool = false)
      @key = Key.new(text, mod, code, shifted_code, base_code, is_repeat)
    end

    def to_s : String
      @key.to_s
    end

    def keystroke : String
      @key.keystroke
    end

    def ==(other : self) : Bool
      @key == other.key
    end

    def_hash @key
  end

  # KeyReleaseEvent represents a key release event.
  struct KeyReleaseEvent
    include KeyEvent

    getter key : Key

    def initialize(@key : Key)
    end

    def initialize(text : String = "", mod : KeyMod = KeyMod::None, code : UInt32 = 0, shifted_code : UInt32 = 0, base_code : UInt32 = 0, is_repeat : Bool = false)
      @key = Key.new(text, mod, code, shifted_code, base_code, is_repeat)
    end

    def to_s : String
      @key.to_s
    end

    def keystroke : String
      @key.keystroke
    end

    def_hash @key
  end

  private KEY_TYPE_STRING = {
    KeyEnter      => "enter",
    KeyTab        => "tab",
    KeyBackspace  => "backspace",
    KeyEscape     => "esc",
    KeySpace      => "space",
    KeyUp         => "up",
    KeyDown       => "down",
    KeyLeft       => "left",
    KeyRight      => "right",
    KeyBegin      => "begin",
    KeyFind       => "find",
    KeyInsert     => "insert",
    KeyDelete     => "delete",
    KeySelect     => "select",
    KeyPgUp       => "pgup",
    KeyPgDown     => "pgdown",
    KeyHome       => "home",
    KeyEnd        => "end",
    KeyKpEnter    => "kpenter",
    KeyKpEqual    => "kpequal",
    KeyKpMultiply => "kpmul",
    KeyKpPlus     => "kpplus",
    KeyKpComma    => "kpcomma",
    KeyKpMinus    => "kpminus",
    KeyKpDecimal  => "kpperiod",
    KeyKpDivide   => "kpdiv",
    KeyKp0        => "kp0",
    KeyKp1        => "kp1",
    KeyKp2        => "kp2",
    KeyKp3        => "kp3",
    KeyKp4        => "kp4",
    KeyKp5        => "kp5",
    KeyKp6        => "kp6",
    KeyKp7        => "kp7",
    KeyKp8        => "kp8",
    KeyKp9        => "kp9",

    # Kitty keyboard extension
    KeyKpSep    => "kpsep",
    KeyKpUp     => "kpup",
    KeyKpDown   => "kpdown",
    KeyKpLeft   => "kpleft",
    KeyKpRight  => "kpright",
    KeyKpPgUp   => "kppgup",
    KeyKpPgDown => "kppgdown",
    KeyKpHome   => "kphome",
    KeyKpEnd    => "kpend",
    KeyKpInsert => "kpinsert",
    KeyKpDelete => "kpdelete",
    KeyKpBegin  => "kpbegin",

    KeyF1  => "f1",
    KeyF2  => "f2",
    KeyF3  => "f3",
    KeyF4  => "f4",
    KeyF5  => "f5",
    KeyF6  => "f6",
    KeyF7  => "f7",
    KeyF8  => "f8",
    KeyF9  => "f9",
    KeyF10 => "f10",
    KeyF11 => "f11",
    KeyF12 => "f12",
    KeyF13 => "f13",
    KeyF14 => "f14",
    KeyF15 => "f15",
    KeyF16 => "f16",
    KeyF17 => "f17",
    KeyF18 => "f18",
    KeyF19 => "f19",
    KeyF20 => "f20",
    KeyF21 => "f21",
    KeyF22 => "f22",
    KeyF23 => "f23",
    KeyF24 => "f24",
    KeyF25 => "f25",
    KeyF26 => "f26",
    KeyF27 => "f27",
    KeyF28 => "f28",
    KeyF29 => "f29",
    KeyF30 => "f30",
    KeyF31 => "f31",
    KeyF32 => "f32",
    KeyF33 => "f33",
    KeyF34 => "f34",
    KeyF35 => "f35",
    KeyF36 => "f36",
    KeyF37 => "f37",
    KeyF38 => "f38",
    KeyF39 => "f39",
    KeyF40 => "f40",
    KeyF41 => "f41",
    KeyF42 => "f42",
    KeyF43 => "f43",
    KeyF44 => "f44",
    KeyF45 => "f45",
    KeyF46 => "f46",
    KeyF47 => "f47",
    KeyF48 => "f48",
    KeyF49 => "f49",
    KeyF50 => "f50",
    KeyF51 => "f51",
    KeyF52 => "f52",
    KeyF53 => "f53",
    KeyF54 => "f54",
    KeyF55 => "f55",
    KeyF56 => "f56",
    KeyF57 => "f57",
    KeyF58 => "f58",
    KeyF59 => "f59",
    KeyF60 => "f60",
    KeyF61 => "f61",
    KeyF62 => "f62",
    KeyF63 => "f63",

    # Kitty keyboard extension
    KeyCapsLock         => "capslock",
    KeyScrollLock       => "scrolllock",
    KeyNumLock          => "numlock",
    KeyPrintScreen      => "printscreen",
    KeyPause            => "pause",
    KeyMenu             => "menu",
    KeyMediaPlay        => "mediaplay",
    KeyMediaPause       => "mediapause",
    KeyMediaPlayPause   => "mediaplaypause",
    KeyMediaReverse     => "mediareverse",
    KeyMediaStop        => "mediastop",
    KeyMediaFastForward => "mediafastforward",
    KeyMediaRewind      => "mediarewind",
    KeyMediaNext        => "medianext",
    KeyMediaPrev        => "mediaprev",
    KeyMediaRecord      => "mediarecord",
    KeyLowerVol         => "lowervol",
    KeyRaiseVol         => "raisevol",
    KeyMute             => "mute",
    KeyLeftShift        => "leftshift",
    KeyLeftAlt          => "leftalt",
    KeyLeftCtrl         => "leftctrl",
    KeyLeftSuper        => "leftsuper",
    KeyLeftHyper        => "lefthyper",
    KeyLeftMeta         => "leftmeta",
    KeyRightShift       => "rightshift",
    KeyRightAlt         => "rightalt",
    KeyRightCtrl        => "rightctrl",
    KeyRightSuper       => "rightsuper",
    KeyRightHyper       => "righthyper",
    KeyRightMeta        => "rightmeta",
    KeyIsoLevel3Shift   => "isolevel3shift",
    KeyIsoLevel5Shift   => "isolevel5shift",
  }
end
