module Input
  KittyDisambiguateEscapeCodes = 1 << 0
  KittyReportEventTypes        = 1 << 1
  KittyReportAlternateKeys     = 1 << 2
  KittyReportAllKeysAsEscCodes = 1 << 3
  KittyReportAssociatedText    = 1 << 4

  private KittyShift    = 1 << 0
  private KittyAlt      = 1 << 1
  private KittyCtrl     = 1 << 2
  private KittySuper    = 1 << 3
  private KittyHyper    = 1 << 4
  private KittyMeta     = 1 << 5
  private KittyCapsLock = 1 << 6
  private KittyNumLock  = 1 << 7

  @@kitty_key_map : Hash(Int32, Key)?

  private def self.kitty_key_map : Hash(Int32, Key)
    @@kitty_key_map ||= begin
      km = {
        Ansi::BS.to_i32  => Key.new(code: KeyBackspace),
        Ansi::HT.to_i32  => Key.new(code: KeyTab),
        Ansi::CR.to_i32  => Key.new(code: KeyEnter),
        Ansi::ESC.to_i32 => Key.new(code: KeyEscape),
        Ansi::DEL.to_i32 => Key.new(code: KeyBackspace),

        57344 => Key.new(code: KeyEscape),
        57345 => Key.new(code: KeyEnter),
        57346 => Key.new(code: KeyTab),
        57347 => Key.new(code: KeyBackspace),
        57348 => Key.new(code: KeyInsert),
        57349 => Key.new(code: KeyDelete),
        57350 => Key.new(code: KeyLeft),
        57351 => Key.new(code: KeyRight),
        57352 => Key.new(code: KeyUp),
        57353 => Key.new(code: KeyDown),
        57354 => Key.new(code: KeyPgUp),
        57355 => Key.new(code: KeyPgDown),
        57356 => Key.new(code: KeyHome),
        57357 => Key.new(code: KeyEnd),
        57358 => Key.new(code: KeyCapsLock),
        57359 => Key.new(code: KeyScrollLock),
        57360 => Key.new(code: KeyNumLock),
        57361 => Key.new(code: KeyPrintScreen),
        57362 => Key.new(code: KeyPause),
        57363 => Key.new(code: KeyMenu),
        57364 => Key.new(code: KeyF1),
        57365 => Key.new(code: KeyF2),
        57366 => Key.new(code: KeyF3),
        57367 => Key.new(code: KeyF4),
        57368 => Key.new(code: KeyF5),
        57369 => Key.new(code: KeyF6),
        57370 => Key.new(code: KeyF7),
        57371 => Key.new(code: KeyF8),
        57372 => Key.new(code: KeyF9),
        57373 => Key.new(code: KeyF10),
        57374 => Key.new(code: KeyF11),
        57375 => Key.new(code: KeyF12),
        57376 => Key.new(code: KeyF13),
        57377 => Key.new(code: KeyF14),
        57378 => Key.new(code: KeyF15),
        57379 => Key.new(code: KeyF16),
        57380 => Key.new(code: KeyF17),
        57381 => Key.new(code: KeyF18),
        57382 => Key.new(code: KeyF19),
        57383 => Key.new(code: KeyF20),
        57384 => Key.new(code: KeyF21),
        57385 => Key.new(code: KeyF22),
        57386 => Key.new(code: KeyF23),
        57387 => Key.new(code: KeyF24),
        57388 => Key.new(code: KeyF25),
        57389 => Key.new(code: KeyF26),
        57390 => Key.new(code: KeyF27),
        57391 => Key.new(code: KeyF28),
        57392 => Key.new(code: KeyF29),
        57393 => Key.new(code: KeyF30),
        57394 => Key.new(code: KeyF31),
        57395 => Key.new(code: KeyF32),
        57396 => Key.new(code: KeyF33),
        57397 => Key.new(code: KeyF34),
        57398 => Key.new(code: KeyF35),
        57399 => Key.new(code: KeyKp0),
        57400 => Key.new(code: KeyKp1),
        57401 => Key.new(code: KeyKp2),
        57402 => Key.new(code: KeyKp3),
        57403 => Key.new(code: KeyKp4),
        57404 => Key.new(code: KeyKp5),
        57405 => Key.new(code: KeyKp6),
        57406 => Key.new(code: KeyKp7),
        57407 => Key.new(code: KeyKp8),
        57408 => Key.new(code: KeyKp9),
        57409 => Key.new(code: KeyKpDecimal),
        57410 => Key.new(code: KeyKpDivide),
        57411 => Key.new(code: KeyKpMultiply),
        57412 => Key.new(code: KeyKpMinus),
        57413 => Key.new(code: KeyKpPlus),
        57414 => Key.new(code: KeyKpEnter),
        57415 => Key.new(code: KeyKpEqual),
        57416 => Key.new(code: KeyKpSep),
        57417 => Key.new(code: KeyKpLeft),
        57418 => Key.new(code: KeyKpRight),
        57419 => Key.new(code: KeyKpUp),
        57420 => Key.new(code: KeyKpDown),
        57421 => Key.new(code: KeyKpPgUp),
        57422 => Key.new(code: KeyKpPgDown),
        57423 => Key.new(code: KeyKpHome),
        57424 => Key.new(code: KeyKpEnd),
        57425 => Key.new(code: KeyKpInsert),
        57426 => Key.new(code: KeyKpDelete),
        57427 => Key.new(code: KeyKpBegin),
        57428 => Key.new(code: KeyMediaPlay),
        57429 => Key.new(code: KeyMediaPause),
        57430 => Key.new(code: KeyMediaPlayPause),
        57431 => Key.new(code: KeyMediaReverse),
        57432 => Key.new(code: KeyMediaStop),
        57433 => Key.new(code: KeyMediaFastForward),
        57434 => Key.new(code: KeyMediaRewind),
        57435 => Key.new(code: KeyMediaNext),
        57436 => Key.new(code: KeyMediaPrev),
        57437 => Key.new(code: KeyMediaRecord),
        57438 => Key.new(code: KeyLowerVol),
        57439 => Key.new(code: KeyRaiseVol),
        57440 => Key.new(code: KeyMute),
        57441 => Key.new(code: KeyLeftShift),
        57442 => Key.new(code: KeyLeftCtrl),
        57443 => Key.new(code: KeyLeftAlt),
        57444 => Key.new(code: KeyLeftSuper),
        57445 => Key.new(code: KeyLeftHyper),
        57446 => Key.new(code: KeyLeftMeta),
        57447 => Key.new(code: KeyRightShift),
        57448 => Key.new(code: KeyRightCtrl),
        57449 => Key.new(code: KeyRightAlt),
        57450 => Key.new(code: KeyRightSuper),
        57451 => Key.new(code: KeyRightHyper),
        57452 => Key.new(code: KeyRightMeta),
        57453 => Key.new(code: KeyIsoLevel3Shift),
        57454 => Key.new(code: KeyIsoLevel5Shift),
      } of Int32 => Key

      # Faulty C0 mappings that some terminals send.
      km[Ansi::NUL.to_i32] = Key.new(code: KeySpace, mod: ModCtrl)
      (Ansi::SOH.to_i32..Ansi::SUB.to_i32).each do |idx|
        km[idx] ||= Key.new(code: (idx + 0x60).to_u32, mod: ModCtrl)
      end
      (Ansi::FS.to_i32..Ansi::US.to_i32).each do |idx|
        km[idx] ||= Key.new(code: (idx + 0x40).to_u32, mod: ModCtrl)
      end
      km
    end
  end

  private def self.from_kitty_mod(mod : Int32) : KeyMod
    m = KeyMod::None
    m |= ModShift if (mod & KittyShift) != 0
    m |= ModAlt if (mod & KittyAlt) != 0
    m |= ModCtrl if (mod & KittyCtrl) != 0
    m |= ModSuper if (mod & KittySuper) != 0
    m |= ModHyper if (mod & KittyHyper) != 0
    m |= ModMeta if (mod & KittyMeta) != 0
    m |= ModCapsLock if (mod & KittyCapsLock) != 0
    m |= ModNumLock if (mod & KittyNumLock) != 0
    m
  end

  private def self.kitty_param_value(value : Int32, def_value : Int32) : Int32
    p = value & Ansi::ParserTransition::ParamMask
    return def_value if p == Ansi::ParserTransition::MissingParam
    p
  end

  private def self.kitty_has_more?(value : Int32) : Bool
    (value & Ansi::ParserTransition::HasMoreFlag) != 0
  end

  private def self.safe_chr(code : Int32) : Char
    return '\u{FFFD}' if code < 0 || code > 0x10FFFF
    return '\u{FFFD}' if code >= 0xD800 && code <= 0xDFFF
    code.chr
  end

  def self.parse_kitty_keyboard(params : Ansi::Params) : Event
    is_release = false
    key = Key.new

    param_idx = 0
    sub_idx = 0
    params.each do |raw|
      case param_idx
      when 0
        case sub_idx
        when 0
          code = kitty_param_value(raw, 1)
          if mapped = kitty_key_map[code]?
            key = mapped.dup
          else
            key.code = safe_chr(code).ord.to_u32
          end
        when 2
          b = safe_chr(kitty_param_value(raw, 1))
          key.base_code = b.ord.to_u32 if b.printable?
          # fallthrough
          s = safe_chr(kitty_param_value(raw, 1))
          key.shifted_code = s.ord.to_u32 if s.printable?
        when 1
          s = safe_chr(kitty_param_value(raw, 1))
          key.shifted_code = s.ord.to_u32 if s.printable?
        end
      when 1
        case sub_idx
        when 0
          mod = kitty_param_value(raw, 1)
          if mod > 1
            key.mod = from_kitty_mod(mod - 1)
            key.text = "" if key.mod > ModShift
          end
        when 1
          case kitty_param_value(raw, 1)
          when 2
            key.repeat = true
          when 3
            is_release = true
          end
        end
      when 2
        code = kitty_param_value(raw, 0)
        key.text += safe_chr(code).to_s if code != 0
      end

      sub_idx += 1
      unless kitty_has_more?(raw)
        param_idx += 1
        sub_idx = 0
      end
    end

    if key.text.empty? && key.code <= Char::MAX_CODEPOINT &&
       key.code.chr.printable? &&
       (key.mod <= ModShift || key.mod == ModCapsLock || key.mod == (ModShift | ModCapsLock))
      if key.mod == KeyMod::None
        key.text = key.code.chr.to_s
      else
        if key.shifted_code != 0 && key.shifted_code <= Char::MAX_CODEPOINT
          key.text = key.shifted_code.chr.to_s
        else
          text_char = key.code.chr
          text_char = text_char.upcase if key.mod.contains(ModShift) || key.mod.contains(ModCapsLock)
          key.text = text_char.to_s
        end
      end
    end

    if is_release
      KeyReleaseEvent.new(key)
    else
      KeyPressEvent.new(key)
    end
  end

  def self.parse_kitty_keyboard_ext(params : Ansi::Params, k : KeyPressEvent) : Event
    key = k.key
    # We have at least 3 parameters; first param is 1; second has subparams.
    if params.size > 2 &&
       kitty_param_value(params[0], 1) == 1 &&
       kitty_has_more?(params[1])
      case kitty_param_value(params[2], 1)
      when 2
        key.repeat = true
      when 3
        return KeyReleaseEvent.new(key)
      end
    end

    KeyPressEvent.new(key)
  end
end
