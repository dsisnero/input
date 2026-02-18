require "../spec_helper"

module Input
  describe "KeyPressEvent" do
    describe "#to_s" do
      it "alt+space" do
        k = KeyPressEvent.new(code: KeySpace, mod: ModAlt)
        k.to_s.should eq "alt+space"
      end

      it "runes" do
        k = KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a")
        k.to_s.should eq "a"
      end

      it "invalid" do
        k = KeyPressEvent.new(code: 99999)
        k.to_s.should eq "\u{1869F}"
      end

      it "space" do
        k = KeyPressEvent.new(code: KeySpace, text: " ")
        k.to_s.should eq "space"
      end

      it "shift+space" do
        k = KeyPressEvent.new(code: KeySpace, mod: ModShift)
        k.to_s.should eq "shift+space"
      end

      it "?" do
        k = KeyPressEvent.new(code: '/'.ord.to_u32, mod: ModShift, text: "?")
        k.to_s.should eq "?"
      end
    end

    describe "#keystroke" do
      it "delegates to key keystroke" do
        k = KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModCtrl | ModAlt)
        k.keystroke.should eq "ctrl+alt+a"
      end
    end

    describe "#key" do
      it "returns underlying key" do
        key = Key.new(text: "a", code: 'a'.ord.to_u32, mod: ModCtrl)
        event = KeyPressEvent.new(key)
        event.key.should eq key
      end
    end
  end

  describe "KeyReleaseEvent" do
    describe "#to_s" do
      it "delegates to key string" do
        k = KeyReleaseEvent.new(code: KeySpace, mod: ModAlt)
        k.to_s.should eq "alt+space"
      end
    end

    describe "#keystroke" do
      it "delegates to key keystroke" do
        k = KeyReleaseEvent.new(code: 'a'.ord.to_u32, mod: ModCtrl | ModAlt)
        k.keystroke.should eq "ctrl+alt+a"
      end
    end

    describe "#key" do
      it "returns underlying key" do
        key = Key.new(text: "a", code: 'a'.ord.to_u32, mod: ModCtrl)
        event = KeyReleaseEvent.new(key)
        event.key.should eq key
      end
    end
  end

  describe "Reader input ports" do
    read_all_events = ->(input : IO) do
      dr = Input::Reader.new_reader(input, "dumb", 0)
      events = [] of Event
      loop do
        batch = dr.read_events
        break if batch.empty?
        events.concat(batch)
      end
      events
    end

    it "ports TestReadLongInput" do
      expect = Array(Event).new(1000) do
        KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a").as(Event)
      end
      read_all_events.call(IO::Memory.new("a" * 1000)).should eq expect
    end

    it "ports TestReadInput cases" do
      cases = {
        "a"    => [KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a").as(Event)],
        " "    => [KeyPressEvent.new(code: KeySpace, text: " ").as(Event)],
        "a\ea" => [
          KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a").as(Event),
          KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModAlt).as(Event),
        ],
        "a\eaa" => [
          KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a").as(Event),
          KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModAlt).as(Event),
          KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a").as(Event),
        ],
        Bytes[0x01]       => [KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModCtrl).as(Event)],
        Bytes[0x01, 0x02] => [
          KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModCtrl).as(Event),
          KeyPressEvent.new(code: 'b'.ord.to_u32, mod: ModCtrl).as(Event),
        ],
        "\ea"  => [KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModAlt).as(Event)],
        "abcd" => [
          KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a").as(Event),
          KeyPressEvent.new(code: 'b'.ord.to_u32, text: "b").as(Event),
          KeyPressEvent.new(code: 'c'.ord.to_u32, text: "c").as(Event),
          KeyPressEvent.new(code: 'd'.ord.to_u32, text: "d").as(Event),
        ],
        "\e[A"                                                          => [KeyPressEvent.new(code: KeyUp).as(Event)],
        Bytes[0x1b, 0x5b, 0x4d, (32 + 0b0100_0000).to_u8, 65_u8, 49_u8] => [
          MouseWheelEvent.new(x: 32, y: 16, button: MouseWheelUp, mod: KeyMod::None).as(Event),
        ],
        Bytes[
          0x1b, 0x5b, 0x4d, (32 + 0b0010_0000).to_u8, (32 + 33).to_u8, (16 + 33).to_u8,
          0x1b, 0x5b, 0x4d, (32 + 0b0000_0011).to_u8, (64 + 33).to_u8, (32 + 33).to_u8,
        ] => [
          MouseMotionEvent.new(x: 32, y: 16, button: MouseLeft, mod: KeyMod::None).as(Event),
          MouseReleaseEvent.new(x: 64, y: 32, button: MouseNone, mod: KeyMod::None).as(Event),
        ],
        "\e[Z"                                          => [KeyPressEvent.new(code: KeyTab, mod: ModShift).as(Event)],
        "\r"                                            => [KeyPressEvent.new(code: KeyEnter).as(Event)],
        "\e\r"                                          => [KeyPressEvent.new(code: KeyEnter, mod: ModAlt).as(Event)],
        "\e[2~"                                         => [KeyPressEvent.new(code: KeyInsert).as(Event)],
        Bytes[0x1b, 0x01]                               => [KeyPressEvent.new(code: 'a'.ord.to_u32, mod: ModCtrl | ModAlt).as(Event)],
        Bytes[0x1b, 0x5b, 0x2d, 0x2d, 0x2d, 0x2d, 0x58] => [UnknownEvent.new("\e[----X").as(Event)],
        "\eOA"                                          => [KeyPressEvent.new(code: KeyUp).as(Event)],
        "\eOB"                                          => [KeyPressEvent.new(code: KeyDown).as(Event)],
        "\eOC"                                          => [KeyPressEvent.new(code: KeyRight).as(Event)],
        "\eOD"                                          => [KeyPressEvent.new(code: KeyLeft).as(Event)],
        "\e\x7f"                                        => [KeyPressEvent.new(code: KeyBackspace, mod: ModAlt).as(Event)],
        Bytes[0x00]                                     => [KeyPressEvent.new(code: KeySpace, mod: ModCtrl).as(Event)],
        Bytes[0x1b, 0x00]                               => [KeyPressEvent.new(code: KeySpace, mod: ModCtrl | ModAlt).as(Event)],
        Bytes[0x1b]                                     => [KeyPressEvent.new(code: KeyEscape).as(Event)],
        Bytes[0x1b, 0x1b]                               => [KeyPressEvent.new(code: KeyEscape, mod: ModAlt).as(Event)],
        "\e[200~a b\e[201~o"                            => [
          PasteStartEvent.new.as(Event),
          PasteEvent.new("a b").as(Event),
          PasteEndEvent.new.as(Event),
          KeyPressEvent.new(code: 'o'.ord.to_u32, text: "o").as(Event),
        ],
        Bytes[
          0x1b, 0x5b, 0x32, 0x30, 0x30, 0x7e, 'a'.ord.to_u8, 0x03, 0x0a, 'b'.ord.to_u8,
          0x1b, 0x5b, 0x32, 0x30, 0x31, 0x7e,
        ] => [
          PasteStartEvent.new.as(Event),
          PasteEvent.new("a\x03\nb").as(Event),
          PasteEndEvent.new.as(Event),
        ],
        Bytes[0xfe]                                                 => [UnknownEvent.new(0xfe_u8.chr.to_s).as(Event)],
        Bytes['a'.ord.to_u8, 0xfe_u8, ' '.ord.to_u8, 'b'.ord.to_u8] => [
          KeyPressEvent.new(code: 'a'.ord.to_u32, text: "a").as(Event),
          UnknownEvent.new(0xfe_u8.chr.to_s).as(Event),
          KeyPressEvent.new(code: KeySpace, text: " ").as(Event),
          KeyPressEvent.new(code: 'b'.ord.to_u32, text: "b").as(Event),
        ],
      }

      cases.each do |input, want|
        io = input.is_a?(Bytes) ? IO::Memory.new(input) : IO::Memory.new(input.as(String))
        read_all_events.call(io).should eq want
      end
    end
  end
end
