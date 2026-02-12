require "./spec_helper"

describe Input do
  describe "Key constants" do
    it "defines KeyExtended" do
      Input::KeyExtended.should be > Char::MAX_CODEPOINT
    end

    it "defines KeyEnter" do
      Input::KeyEnter.should eq(0x0D_u32)
    end

    it "defines KeySpace" do
      Input::KeySpace.should eq(0x20_u32)
    end
  end

  describe "Mouse constants" do
    it "defines MouseLeft" do
      Input::MouseLeft.should eq(1_u8)
    end

    it "defines MouseRight" do
      Input::MouseRight.should eq(3_u8)
    end
  end

  describe "Key struct" do
    it "can be instantiated" do
      key = Input::Key.new("a", Input::KeyMod::None, Input::KeyEnter)
      key.text.should eq("a")
      key.code.should eq(Input::KeyEnter)
    end

    it "to_s returns text when present" do
      key = Input::Key.new("b", Input::KeyMod::None, 'b'.ord.to_u32)
      key.to_s.should eq("b")
    end
  end
end
