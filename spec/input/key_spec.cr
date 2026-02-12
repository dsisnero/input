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
  end
end
