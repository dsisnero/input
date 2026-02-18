require "../spec_helper"

module Input
  describe ".build_terminfo_keys" do
    it "returns key mappings when terminfo can be loaded" do
      table = Input.build_terminfo_keys(0, "xterm")
      table.empty?.should be_false
    end

    it "returns empty mappings for unknown terminfo" do
      table = Input.build_terminfo_keys(0, "definitely-not-a-real-term")
      table.should eq Hash(String, Key).new
    end
  end
end
