require "../spec_helper"

module Input
  record SeqTest, seq : Bytes, events : Array(Event)
  F3_CUR_POS_REGEXP = /\e\[1;(\d+)R/
  SEQUENCES         = Input.build_keys_table(FlagTerminfo, "dumb")
  describe Parser do
    it "parses alt+shift+tab and printable letters" do
      input = Bytes[
        0x1b, 0x1b, 0x5b, 0x5a, # ESC ESC [ Z
        0x74, 0x65, 0x73, 0x74, # t e s t
        0x00,                   # NUL
      ]
      want = [
        KeyPressEvent.new(code: KeyTab, mod: ModShift | ModAlt),
        KeyPressEvent.new(code: 't'.ord.to_u32, text: "t"),
        KeyPressEvent.new(code: 'e'.ord.to_u32, text: "e"),
        KeyPressEvent.new(code: 's'.ord.to_u32, text: "s"),
        KeyPressEvent.new(code: 't'.ord.to_u32, text: "t"),
        KeyPressEvent.new(code: KeySpace, mod: ModCtrl),
      ]
      parser = Parser.new
      i = 0
      slice = input
      while slice.size > 0
        if i >= want.size
          fail "reached end of want events"
        end
        n, got = parser.parse_sequence(slice)
        got.should eq want[i]
        slice = slice + n
        i += 1
      end
    end

    it "parses complex sequence with color, mode reports, etc." do
      # Port of Go's TestParseSequence_Events
      input = Bytes[
        0x1b, 0x1b, 0x5b, 0x5a,                                                                                                                         # ESC ESC [ Z (alt+shift+tab)
        0x74, 0x65, 0x73, 0x74,                                                                                                                         # t e s t (printable letters)
        0x00,                                                                                                                                           # NUL (ctrl+space)
        0x1b, 0x5d, 0x31, 0x30, 0x3b, 0x72, 0x67, 0x62, 0x3a, 0x31, 0x32, 0x33, 0x34, 0x2f, 0x31, 0x32, 0x33, 0x34, 0x2f, 0x31, 0x32, 0x33, 0x34, 0x07, # OSC 10;rgb:1234/1234/1234 BEL
        0x1b, 0x5b, 0x32, 0x37, 0x3b, 0x32, 0x3b, 0x32, 0x37, 0x7e,                                                                                     # CSI 27;2;27~ (shift+escape)
        0x1b, 0x5b, 0x3f, 0x31, 0x30, 0x34, 0x39, 0x3b, 0x32, 0x24, 0x79,                                                                               # CSI ?1049;2$y (mode report)
        0x1b, 0x5b, 0x34, 0x3b, 0x31, 0x24, 0x79,                                                                                                       # CSI 4;1$y (mode report)
      ]
      want = [
        KeyPressEvent.new(code: KeyTab, mod: ModShift | ModAlt),
        KeyPressEvent.new(code: 't'.ord.to_u32, text: "t"),
        KeyPressEvent.new(code: 'e'.ord.to_u32, text: "e"),
        KeyPressEvent.new(code: 's'.ord.to_u32, text: "s"),
        KeyPressEvent.new(code: 't'.ord.to_u32, text: "t"),
        KeyPressEvent.new(code: KeySpace, mod: ModCtrl),
        ForegroundColorEvent.new(RGBA.new(0x12, 0x12, 0x12, 0xff)),
        KeyPressEvent.new(code: KeyEscape, mod: ModShift),
        ModeReportEvent.new(mode: 1049, value: 2), # AltScreenSaveCursorMode, ModeReset
        ModeReportEvent.new(mode: 4, value: 1),    # InsertReplaceMode, ModeSet
      ]
      parser = Parser.new
      i = 0
      slice = input
      while slice.size > 0
        if i >= want.size
          fail "reached end of want events"
        end
        n, got = parser.parse_sequence(slice)
        got.should eq want[i]
        slice = slice + n
        i += 1
      end
    end

    it "parses kitty keyboard CSI u variants" do
      parser = Parser.new

      n, got = parser.parse_sequence("\e[195;u".to_slice)
      n.should be > 0
      got.should eq KeyPressEvent.new(text: "Ã", code: 'Ã'.ord.to_u32)

      n, got = parser.parse_sequence("\e[195;2:2u".to_slice)
      n.should be > 0
      got.should eq KeyPressEvent.new(code: 'Ã'.ord.to_u32, text: "Ã", is_repeat: true, mod: ModShift)

      n, got = parser.parse_sequence("\e[195;2:3u".to_slice)
      n.should be > 0
      got.should eq KeyReleaseEvent.new(code: 'Ã'.ord.to_u32, text: "Ã", mod: ModShift)

      n, got = parser.parse_sequence("\e[97;2;65u".to_slice)
      n.should be > 0
      got.should eq KeyPressEvent.new(code: 'a'.ord.to_u32, text: "A", mod: ModShift)
    end

    it "parses xterm modifyOtherKeys sequences" do
      parser = Parser.new

      n, got = parser.parse_sequence("\e[27;3;65~".to_slice)
      n.should be > 0
      got.should eq KeyPressEvent.new(code: 'A'.ord.to_u32, mod: ModAlt)

      n, got = parser.parse_sequence("\e[27;3;27~".to_slice)
      n.should be > 0
      got.should eq KeyPressEvent.new(code: KeyEscape, mod: ModAlt)
    end

    it "parses all sequences" do
      # Port of Go's TestParseSequence

      td = [] of SeqTest
      SEQUENCES.each do |seq, key|
        k = KeyPressEvent.new(key)
        st = SeqTest.new(seq.to_slice, [k] of Event)
        if F3_CUR_POS_REGEXP.match(seq)
          st = SeqTest.new(seq.to_slice, [k, CursorPositionEvent.new(x: key.mod.value.to_i, y: 0)] of Event)
        end
        td << st
      end

      # Additional special cases.
      td << SeqTest.new(Bytes[0x1b, 0x5b, 0x2d, 0x2d, 0x2d, 0x2d, 0x58], # ESC [ - - - - X
        [UnknownEvent.new(String.new(Bytes[0x1b, 0x5b, 0x2d, 0x2d, 0x2d, 0x2d, 0x58]))] of Event      )
      td << SeqTest.new(Bytes[0x20],
        [KeyPressEvent.new(code: KeySpace, text: " ")] of Event)
      td << SeqTest.new(Bytes[0x1b, 0x20],
        [KeyPressEvent.new(code: KeySpace, mod: ModAlt)] of Event)

      # Additional test cases from TestParseSequence
      # Background color
      td << SeqTest.new("\e]11;rgb:1234/1234/1234\a".to_slice,
        [BackgroundColorEvent.new(color: RGBA.new(0x12, 0x12, 0x12, 0xff))] of Event)
      td << SeqTest.new("\e]11;rgb:1234/1234/1234\e\\".to_slice,
        [BackgroundColorEvent.new(color: RGBA.new(0x12, 0x12, 0x12, 0xff))] of Event)
      td << SeqTest.new("\e]11;rgb:1234/1234/1234\e".to_slice,
        [UnknownEvent.new("\e]11;rgb:1234/1234/1234\e")] of Event)

      # Kitty Graphics response.
      kgo1 = Ansi::Kitty::Options.new
      kgo1.action = Ansi::Kitty::Transmit.to_u8
      td << SeqTest.new("\e_Ga=t;OK\e\\".to_slice,
        [KittyGraphicsEvent.new(options: kgo1, payload: "OK")] of Event)
      kgo2 = Ansi::Kitty::Options.new
      kgo2.id = 99
      kgo2.number = 13
      td << SeqTest.new("\e_Gi=99,I=13;OK\e\\".to_slice,
        [KittyGraphicsEvent.new(options: kgo2, payload: "OK")] of Event)
      kgo3 = Ansi::Kitty::Options.new
      kgo3.id = 1337
      kgo3.quite = 1_u8
      td << SeqTest.new("\e_Gi=1337,q=1;EINVAL:your face\e\\".to_slice,
        [KittyGraphicsEvent.new(options: kgo3, payload: "EINVAL:your face")] of Event)

      # Xterm modifyOtherKeys CSI 27 ; <modifier> ; <code> ~
      td << SeqTest.new("\e[27;3;20320~".to_slice,
        [KeyPressEvent.new(code: '你'.ord.to_u32, mod: ModAlt)] of Event)
      td << SeqTest.new("\e[27;3;65~".to_slice,
        [KeyPressEvent.new(code: 'A'.ord.to_u32, mod: ModAlt)] of Event)
      td << SeqTest.new("\e[27;3;8~".to_slice,
        [KeyPressEvent.new(code: KeyBackspace, mod: ModAlt)] of Event)
      td << SeqTest.new("\e[27;3;27~".to_slice,
        [KeyPressEvent.new(code: KeyEscape, mod: ModAlt)] of Event)
      td << SeqTest.new("\e[27;3;127~".to_slice,
        [KeyPressEvent.new(code: KeyBackspace, mod: ModAlt)] of Event)

      # Xterm report window text area size.
      td << SeqTest.new("\e[4;24;80t".to_slice,
        [WindowOpEvent.new(op: 4, args: [24, 80])] of Event)

      # Kitty keyboard / CSI u (fixterms)
      td << SeqTest.new("\e[1B".to_slice,
        [KeyPressEvent.new(code: KeyDown)] of Event)
      td << SeqTest.new("\e[1;B".to_slice,
        [KeyPressEvent.new(code: KeyDown)] of Event)
      td << SeqTest.new("\e[1;4B".to_slice,
        [KeyPressEvent.new(mod: ModShift | ModAlt, code: KeyDown)] of Event)
      td << SeqTest.new("\e[1;4:1B".to_slice,
        [KeyPressEvent.new(mod: ModShift | ModAlt, code: KeyDown)] of Event)
      td << SeqTest.new("\e[1;4:2B".to_slice,
        [KeyPressEvent.new(mod: ModShift | ModAlt, code: KeyDown, is_repeat: true)] of Event)
      td << SeqTest.new("\e[1;4:3B".to_slice,
        [KeyReleaseEvent.new(mod: ModShift | ModAlt, code: KeyDown)] of Event)
      td << SeqTest.new("\e[8~".to_slice,
        [KeyPressEvent.new(code: KeyEnd)] of Event)
      td << SeqTest.new("\e[8;~".to_slice,
        [KeyPressEvent.new(code: KeyEnd)] of Event)
      td << SeqTest.new("\e[8;10~".to_slice,
        [KeyPressEvent.new(mod: ModShift | ModMeta, code: KeyEnd)] of Event)
      td << SeqTest.new("\e[27;4u".to_slice,
        [KeyPressEvent.new(mod: ModShift | ModAlt, code: KeyEscape)] of Event)
      td << SeqTest.new("\e[127;4u".to_slice,
        [KeyPressEvent.new(mod: ModShift | ModAlt, code: KeyBackspace)] of Event)
      td << SeqTest.new("\e[57358;4u".to_slice,
        [KeyPressEvent.new(mod: ModShift | ModAlt, code: KeyCapsLock)] of Event)
      td << SeqTest.new("\e[9;2u".to_slice,
        [KeyPressEvent.new(mod: ModShift, code: KeyTab)] of Event)
      td << SeqTest.new("\e[195;u".to_slice,
        [KeyPressEvent.new(text: "Ã", code: 'Ã'.ord.to_u32)] of Event)
      td << SeqTest.new("\e[20320;2u".to_slice,
        [KeyPressEvent.new(text: "你", mod: ModShift, code: '你'.ord.to_u32)] of Event)
      td << SeqTest.new("\e[195;:1u".to_slice,
        [KeyPressEvent.new(text: "Ã", code: 'Ã'.ord.to_u32)] of Event)
      td << SeqTest.new("\e[195;2:3u".to_slice,
        [KeyReleaseEvent.new(code: 'Ã'.ord.to_u32, text: "Ã", mod: ModShift)] of Event)
      td << SeqTest.new("\e[195;2:2u".to_slice,
        [KeyPressEvent.new(code: 'Ã'.ord.to_u32, text: "Ã", is_repeat: true, mod: ModShift)] of Event)
      td << SeqTest.new("\e[195;2:1u".to_slice,
        [KeyPressEvent.new(code: 'Ã'.ord.to_u32, text: "Ã", mod: ModShift)] of Event)
      td << SeqTest.new("\e[195;2:3u".to_slice,
        [KeyReleaseEvent.new(code: 'Ã'.ord.to_u32, text: "Ã", mod: ModShift)] of Event)
      td << SeqTest.new("\e[97;2;65u".to_slice,
        [KeyPressEvent.new(code: 'a'.ord.to_u32, text: "A", mod: ModShift)] of Event)
      td << SeqTest.new("\e[97;;229u".to_slice,
        [KeyPressEvent.new(code: 'a'.ord.to_u32, text: "å")] of Event)

      # focus/blur
      td << SeqTest.new(Bytes[0x1b, 0x5b, 0x49],
        [FocusEvent.new] of Event)
      td << SeqTest.new(Bytes[0x1b, 0x5b, 0x4f],
        [BlurEvent.new] of Event)

      # Mouse event.
      td << SeqTest.new(Bytes[0x1b, 0x5b, 0x4d, 0x60, 0x41, 0x31],
        [MouseWheelEvent.new(x: 32, y: 16, button: MouseWheelUp, mod: KeyMod::None)] of Event)
      # SGR Mouse event.
      td << SeqTest.new("\e[<0;33;17M".to_slice,
        [MouseClickEvent.new(x: 32, y: 16, button: MouseLeft, mod: KeyMod::None)] of Event)

      # Runes.
      td << SeqTest.new(Bytes[0x61],
        [KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a")] of Event)
      td << SeqTest.new(Bytes[0x1b, 0x61],
        [KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModAlt)] of Event)
      td << SeqTest.new(Bytes[0x61, 0x61, 0x61],
        [KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a"),
         KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a"),
         KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a")] of Event)

      # Multi-byte rune.
      td << SeqTest.new("☃".to_slice,
        [KeyPressEvent.new(code: '☃'.ord.to_u32, text: "☃")] of Event)
      td << SeqTest.new("\e☃".to_slice,
        [KeyPressEvent.new(code: '☃'.ord.to_u32, mod: ModAlt)] of Event)

      # Standalone control characters.
      td << SeqTest.new(Bytes[0x1b],
        [KeyPressEvent.new(code: KeyEscape)] of Event)
      td << SeqTest.new(Bytes[0x01], # SOH
        [KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModCtrl)] of Event      )
      td << SeqTest.new(Bytes[0x1b, 0x01],
        [KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModCtrl | ModAlt)] of Event)
      td << SeqTest.new(Bytes[0x00], # NUL
        [KeyPressEvent.new(code: KeySpace, mod: ModCtrl)] of Event      )
      td << SeqTest.new(Bytes[0x1b, 0x00],
        [KeyPressEvent.new(code: KeySpace, mod: ModCtrl | ModAlt)] of Event)

      # C1 control characters.
      td << SeqTest.new(Bytes[0x80],
        [KeyPressEvent.new(code: (0x80 - '@'.ord).to_u32, mod: ModCtrl | ModAlt)] of Event)

      {% unless flag?(:windows) %}
        td << SeqTest.new(Bytes[0xfe],
          [UnknownEvent.new(0xfe_u8.chr.to_s)] of Event)
      {% end %}

      parser = Parser.new
      td.each do |test_case|
        events = [] of Event
        buf = test_case.seq
        while buf.size > 0
          n, got = parser.parse_sequence(buf)
          got.should_not be_nil
          event = got.not_nil! # ameba:disable Lint/NotNil
          case event
          when MultiEvent
            events.concat(event.events)
          else
            events << event
          end
          buf = buf + n
        end
        if events != test_case.events
          fail "sequence #{String.new(test_case.seq).inspect} expected #{test_case.events.inspect}, got #{events.inspect}"
        end
      end
    end
  end
end
