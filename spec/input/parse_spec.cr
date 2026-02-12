require "../spec_helper"

module Input
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
  end
end
