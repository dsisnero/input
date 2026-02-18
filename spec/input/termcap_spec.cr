require "../spec_helper"

module Input
  describe ".parse_termcap" do
    it "parses hex encoded name/value pairs" do
      # "TN=xterm-256color;am"
      input = "544e=787465726d2d323536636f6c6f72;616d".to_slice
      Input.parse_termcap(input).should eq CapabilityEvent.new("TN=xterm-256color;am")
    end

    it "returns empty capability event for empty input" do
      Input.parse_termcap(Bytes.empty).should eq CapabilityEvent.new("")
    end

    it "skips entries with invalid name or value encoding" do
      # Invalid name "zz", invalid value "zz", then valid "am".
      input = "zz=3132;544e=zz;616d".to_slice
      Input.parse_termcap(input).should eq CapabilityEvent.new("am")
    end
  end
end
