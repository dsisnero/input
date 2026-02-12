require "../spec_helper"

module Input
  describe "MouseEvent" do
    describe "#to_s" do
      it "returns correct string representations" do
        test_cases = [
          {
            name:     "unknown",
            event:    MouseClickEvent.new(0, 0, 0xff_u8, KeyMod::None),
            expected: "unknown",
          },
          {
            name:     "left",
            event:    MouseClickEvent.new(0, 0, MouseLeft, KeyMod::None),
            expected: "left",
          },
          {
            name:     "right",
            event:    MouseClickEvent.new(0, 0, MouseRight, KeyMod::None),
            expected: "right",
          },
          {
            name:     "middle",
            event:    MouseClickEvent.new(0, 0, MouseMiddle, KeyMod::None),
            expected: "middle",
          },
          {
            name:     "release",
            event:    MouseReleaseEvent.new(0, 0, MouseNone, KeyMod::None),
            expected: "",
          },
          {
            name:     "wheelup",
            event:    MouseWheelEvent.new(0, 0, MouseWheelUp, KeyMod::None),
            expected: "wheelup",
          },
          {
            name:     "wheeldown",
            event:    MouseWheelEvent.new(0, 0, MouseWheelDown, KeyMod::None),
            expected: "wheeldown",
          },
          {
            name:     "wheelleft",
            event:    MouseWheelEvent.new(0, 0, MouseWheelLeft, KeyMod::None),
            expected: "wheelleft",
          },
          {
            name:     "wheelright",
            event:    MouseWheelEvent.new(0, 0, MouseWheelRight, KeyMod::None),
            expected: "wheelright",
          },
          {
            name:     "motion",
            event:    MouseMotionEvent.new(0, 0, MouseNone, KeyMod::None),
            expected: "motion",
          },
          {
            name:     "shift+left",
            event:    MouseReleaseEvent.new(0, 0, MouseLeft, ModShift),
            expected: "shift+left",
          },
          {
            name:     "shift+left",
            event:    MouseClickEvent.new(0, 0, MouseLeft, ModShift),
            expected: "shift+left",
          },
          {
            name:     "ctrl+shift+left",
            event:    MouseClickEvent.new(0, 0, MouseLeft, ModCtrl | ModShift),
            expected: "ctrl+shift+left",
          },
          {
            name:     "alt+left",
            event:    MouseClickEvent.new(0, 0, MouseLeft, ModAlt),
            expected: "alt+left",
          },
          {
            name:     "ctrl+left",
            event:    MouseClickEvent.new(0, 0, MouseLeft, ModCtrl),
            expected: "ctrl+left",
          },
          {
            name:     "ctrl+alt+left",
            event:    MouseClickEvent.new(0, 0, MouseLeft, ModAlt | ModCtrl),
            expected: "ctrl+alt+left",
          },
          {
            name:     "ctrl+alt+shift+left",
            event:    MouseClickEvent.new(0, 0, MouseLeft, ModAlt | ModCtrl | ModShift),
            expected: "ctrl+alt+shift+left",
          },
          {
            name:     "ignore coordinates",
            event:    MouseClickEvent.new(100, 200, MouseLeft, KeyMod::None),
            expected: "left",
          },
          {
            name:     "broken type",
            event:    MouseClickEvent.new(0, 0, 120_u8, KeyMod::None),
            expected: "unknown",
          },
        ]

        test_cases.each do |test_case|
          actual = test_case[:event].to_s
          actual.should eq test_case[:expected]
        end
      end
    end

    it "parses X10 mouse down events" do
      encode = ->(b : UInt8, x : Int32, y : Int32) do
        Bytes[
          0x1b, # ESC
          '['.ord,
          'M'.ord,
          32_u8 + b,
          (x + 32 + 1).to_u8!,
          (y + 32 + 1).to_u8!,
        ]
      end

      test_cases = [
        # Position.
        {
          name:     "zero position",
          buf:      encode.call(0b0000_0000_u8, 0, 0),
          expected: MouseClickEvent.new(0, 0, MouseLeft, KeyMod::None),
        },
        {
          name:     "max position",
          buf:      encode.call(0b0000_0000_u8, 222, 222),
          expected: MouseClickEvent.new(222, 222, MouseLeft, KeyMod::None),
        },
        # Simple.
        {
          name:     "left",
          buf:      encode.call(0b0000_0000_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseLeft, KeyMod::None),
        },
        {
          name:     "left in motion",
          buf:      encode.call(0b0010_0000_u8, 32, 16),
          expected: MouseMotionEvent.new(32, 16, MouseLeft, KeyMod::None),
        },
        {
          name:     "middle",
          buf:      encode.call(0b0000_0001_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseMiddle, KeyMod::None),
        },
        {
          name:     "middle in motion",
          buf:      encode.call(0b0010_0001_u8, 32, 16),
          expected: MouseMotionEvent.new(32, 16, MouseMiddle, KeyMod::None),
        },
        {
          name:     "right",
          buf:      encode.call(0b0000_0010_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseRight, KeyMod::None),
        },
        {
          name:     "right in motion",
          buf:      encode.call(0b0010_0010_u8, 32, 16),
          expected: MouseMotionEvent.new(32, 16, MouseRight, KeyMod::None),
        },
        {
          name:     "motion",
          buf:      encode.call(0b0010_0011_u8, 32, 16),
          expected: MouseMotionEvent.new(32, 16, MouseNone, KeyMod::None),
        },
        {
          name:     "wheel up",
          buf:      encode.call(0b0100_0000_u8, 32, 16),
          expected: MouseWheelEvent.new(32, 16, MouseWheelUp, KeyMod::None),
        },
        {
          name:     "wheel down",
          buf:      encode.call(0b0100_0001_u8, 32, 16),
          expected: MouseWheelEvent.new(32, 16, MouseWheelDown, KeyMod::None),
        },
        {
          name:     "wheel left",
          buf:      encode.call(0b0100_0010_u8, 32, 16),
          expected: MouseWheelEvent.new(32, 16, MouseWheelLeft, KeyMod::None),
        },
        {
          name:     "wheel right",
          buf:      encode.call(0b0100_0011_u8, 32, 16),
          expected: MouseWheelEvent.new(32, 16, MouseWheelRight, KeyMod::None),
        },
        {
          name:     "release",
          buf:      encode.call(0b0000_0011_u8, 32, 16),
          expected: MouseReleaseEvent.new(32, 16, MouseNone, KeyMod::None),
        },
        {
          name:     "backward",
          buf:      encode.call(0b1000_0000_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseBackward, KeyMod::None),
        },
        {
          name:     "forward",
          buf:      encode.call(0b1000_0001_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseForward, KeyMod::None),
        },
        {
          name:     "button 10",
          buf:      encode.call(0b1000_0010_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseButton10, KeyMod::None),
        },
        {
          name:     "button 11",
          buf:      encode.call(0b1000_0011_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseButton11, KeyMod::None),
        },
        # Combinations.
        {
          name:     "alt+right",
          buf:      encode.call(0b0000_1010_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseRight, ModAlt),
        },
        {
          name:     "ctrl+right",
          buf:      encode.call(0b0001_0010_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseRight, ModCtrl),
        },
        {
          name:     "left in motion",
          buf:      encode.call(0b0010_0000_u8, 32, 16),
          expected: MouseMotionEvent.new(32, 16, MouseLeft, KeyMod::None),
        },
        {
          name:     "alt+right in motion",
          buf:      encode.call(0b0010_1010_u8, 32, 16),
          expected: MouseMotionEvent.new(32, 16, MouseRight, ModAlt),
        },
        {
          name:     "ctrl+right in motion",
          buf:      encode.call(0b0011_0010_u8, 32, 16),
          expected: MouseMotionEvent.new(32, 16, MouseRight, ModCtrl),
        },
        {
          name:     "ctrl+alt+right",
          buf:      encode.call(0b0001_1010_u8, 32, 16),
          expected: MouseClickEvent.new(32, 16, MouseRight, ModAlt | ModCtrl),
        },
        {
          name:     "ctrl+wheel up",
          buf:      encode.call(0b0101_0000_u8, 32, 16),
          expected: MouseWheelEvent.new(32, 16, MouseWheelUp, ModCtrl),
        },
        {
          name:     "alt+wheel down",
          buf:      encode.call(0b0100_1001_u8, 32, 16),
          expected: MouseWheelEvent.new(32, 16, MouseWheelDown, ModAlt),
        },
        {
          name:     "ctrl+alt+wheel down",
          buf:      encode.call(0b0101_1001_u8, 32, 16),
          expected: MouseWheelEvent.new(32, 16, MouseWheelDown, ModAlt | ModCtrl),
        },
        # Overflow position.
        {
          name:     "overflow position",
          buf:      encode.call(0b0010_0000_u8, 250, 223),
          expected: MouseMotionEvent.new(-6, -33, MouseLeft, KeyMod::None),
        },
      ]

      test_cases.each do |test_case|
        actual = Input.parse_x10_mouse_event(test_case[:buf])
        actual.should eq test_case[:expected]
      end
    end

    it "parses SGR mouse events" do
      encode = ->(b : Int32, x : Int32, y : Int32, release : Bool) do
        cmd = release ? 'm'.ord : 'M'.ord
        params = [b, x + 1, y + 1]
        {cmd, params}
      end

      test_cases = [
        # Position.
        {
          name:     "zero position",
          buf:      encode.call(0, 0, 0, false),
          expected: MouseClickEvent.new(0, 0, MouseLeft, KeyMod::None),
        },
        {
          name:     "225 position",
          buf:      encode.call(0, 225, 225, false),
          expected: MouseClickEvent.new(225, 225, MouseLeft, KeyMod::None),
        },
        # Simple.
        {
          name:     "left",
          buf:      encode.call(0, 32, 16, false),
          expected: MouseClickEvent.new(32, 16, MouseLeft, KeyMod::None),
        },
        {
          name:     "left in motion",
          buf:      encode.call(32, 32, 16, false),
          expected: MouseMotionEvent.new(32, 16, MouseLeft, KeyMod::None),
        },
        {
          name:     "left release",
          buf:      encode.call(0, 32, 16, true),
          expected: MouseReleaseEvent.new(32, 16, MouseLeft, KeyMod::None),
        },
        {
          name:     "middle",
          buf:      encode.call(1, 32, 16, false),
          expected: MouseClickEvent.new(32, 16, MouseMiddle, KeyMod::None),
        },
        {
          name:     "middle in motion",
          buf:      encode.call(33, 32, 16, false),
          expected: MouseMotionEvent.new(32, 16, MouseMiddle, KeyMod::None),
        },
        {
          name:     "middle release",
          buf:      encode.call(1, 32, 16, true),
          expected: MouseReleaseEvent.new(32, 16, MouseMiddle, KeyMod::None),
        },
        {
          name:     "right",
          buf:      encode.call(2, 32, 16, false),
          expected: MouseClickEvent.new(32, 16, MouseRight, KeyMod::None),
        },
        {
          name:     "right release",
          buf:      encode.call(2, 32, 16, true),
          expected: MouseReleaseEvent.new(32, 16, MouseRight, KeyMod::None),
        },
        {
          name:     "motion",
          buf:      encode.call(35, 32, 16, false),
          expected: MouseMotionEvent.new(32, 16, MouseNone, KeyMod::None),
        },
        {
          name:     "wheel up",
          buf:      encode.call(64, 32, 16, false),
          expected: MouseWheelEvent.new(32, 16, MouseWheelUp, KeyMod::None),
        },
        {
          name:     "wheel down",
          buf:      encode.call(65, 32, 16, false),
          expected: MouseWheelEvent.new(32, 16, MouseWheelDown, KeyMod::None),
        },
        {
          name:     "wheel left",
          buf:      encode.call(66, 32, 16, false),
          expected: MouseWheelEvent.new(32, 16, MouseWheelLeft, KeyMod::None),
        },
        {
          name:     "wheel right",
          buf:      encode.call(67, 32, 16, false),
          expected: MouseWheelEvent.new(32, 16, MouseWheelRight, KeyMod::None),
        },
        {
          name:     "backward",
          buf:      encode.call(128, 32, 16, false),
          expected: MouseClickEvent.new(32, 16, MouseBackward, KeyMod::None),
        },
        {
          name:     "backward in motion",
          buf:      encode.call(160, 32, 16, false),
          expected: MouseMotionEvent.new(32, 16, MouseBackward, KeyMod::None),
        },
        {
          name:     "forward",
          buf:      encode.call(129, 32, 16, false),
          expected: MouseClickEvent.new(32, 16, MouseForward, KeyMod::None),
        },
        {
          name:     "forward in motion",
          buf:      encode.call(161, 32, 16, false),
          expected: MouseMotionEvent.new(32, 16, MouseForward, KeyMod::None),
        },
        # Combinations.
        {
          name:     "alt+right",
          buf:      encode.call(10, 32, 16, false),
          expected: MouseClickEvent.new(32, 16, MouseRight, ModAlt),
        },
        {
          name:     "ctrl+right",
          buf:      encode.call(18, 32, 16, false),
          expected: MouseClickEvent.new(32, 16, MouseRight, ModCtrl),
        },
        {
          name:     "ctrl+alt+right",
          buf:      encode.call(26, 32, 16, false),
          expected: MouseClickEvent.new(32, 16, MouseRight, ModAlt | ModCtrl),
        },
        {
          name:     "alt+wheel",
          buf:      encode.call(73, 32, 16, false),
          expected: MouseWheelEvent.new(32, 16, MouseWheelDown, ModAlt),
        },
        {
          name:     "ctrl+wheel",
          buf:      encode.call(81, 32, 16, false),
          expected: MouseWheelEvent.new(32, 16, MouseWheelDown, ModCtrl),
        },
        {
          name:     "ctrl+alt+wheel",
          buf:      encode.call(89, 32, 16, false),
          expected: MouseWheelEvent.new(32, 16, MouseWheelDown, ModAlt | ModCtrl),
        },
      ]

      test_cases.each do |test_case|
        cmd, params = test_case[:buf]
        actual = Input.parse_sgr_mouse_event(cmd, params)
        actual.should eq test_case[:expected]
      end
    end
  end
end
