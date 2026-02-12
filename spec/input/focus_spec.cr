require "../spec_helper"

module Input
  describe Parser do
    it "parses focus event" do
      input = Bytes[0x1b, 0x5b, 0x49] # CSI I
      parser = Parser.new
      n, event = parser.parse_sequence(input)
      n.should eq 3
      event.should be_a(FocusEvent)
    end

    it "parses blur event" do
      input = Bytes[0x1b, 0x5b, 0x4f] # CSI O
      parser = Parser.new
      n, event = parser.parse_sequence(input)
      n.should eq 3
      event.should be_a(BlurEvent)
    end
  end
end
