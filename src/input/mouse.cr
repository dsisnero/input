module Input
  # MouseButton represents the button that was pressed during a mouse message.
  alias MouseButton = UInt8

  # Mouse event buttons
  #
  # This is based on X11 mouse button codes.
  #
  # 1 = left button
  # 2 = middle button (pressing the scroll wheel)
  # 3 = right button
  # 4 = turn scroll wheel up
  # 5 = turn scroll wheel down
  # 6 = push scroll wheel left
  # 7 = push scroll wheel right
  # 8 = 4th button (aka browser backward button)
  # 9 = 5th button (aka browser forward button)
  # 10
  # 11
  #
  # Other buttons are not supported.
  MouseNone     =  0_u8
  MouseButton1  =  1_u8
  MouseButton2  =  2_u8
  MouseButton3  =  3_u8
  MouseButton4  =  4_u8
  MouseButton5  =  5_u8
  MouseButton6  =  6_u8
  MouseButton7  =  7_u8
  MouseButton8  =  8_u8
  MouseButton9  =  9_u8
  MouseButton10 = 10_u8
  MouseButton11 = 11_u8

  MouseLeft       = MouseButton1
  MouseMiddle     = MouseButton2
  MouseRight      = MouseButton3
  MouseWheelUp    = MouseButton4
  MouseWheelDown  = MouseButton5
  MouseWheelLeft  = MouseButton6
  MouseWheelRight = MouseButton7
  MouseBackward   = MouseButton8
  MouseForward    = MouseButton9
  MouseRelease    = MouseNone

  private MOUSE_BUTTONS = {
    MouseNone       => "none",
    MouseLeft       => "left",
    MouseMiddle     => "middle",
    MouseRight      => "right",
    MouseWheelUp    => "wheelup",
    MouseWheelDown  => "wheeldown",
    MouseWheelLeft  => "wheelleft",
    MouseWheelRight => "wheelright",
    MouseBackward   => "backward",
    MouseForward    => "forward",
    MouseButton10   => "button10",
    MouseButton11   => "button11",
  }

  # Returns a string representation of the mouse button.
  def self.to_s(button : MouseButton) : String
    MOUSE_BUTTONS[button]? || "unknown"
  end

  # MouseEvent represents a mouse message. This is a generic mouse message that
  # can represent any kind of mouse event.
  module MouseEvent
    abstract def to_s : String
    abstract def mouse : Mouse
  end

  # Mouse represents a Mouse message. Use MouseEvent to represent all mouse
  # messages.
  #
  # The X and Y coordinates are zero-based, with (0,0) being the upper left
  # corner of the terminal.
  #
  # // Catch all mouse events
  # switch Event := Event.(type) {
  # case MouseEvent:
  #     m := Event.Mouse()
  #     fmt.Println("Mouse event:", m.X, m.Y, m)
  # }
  #
  # // Only catch mouse click events
  # switch Event := Event.(type) {
  # case MouseClickEvent:
  #     fmt.Println("Mouse click event:", Event.X, Event.Y, Event)
  # }
  struct Mouse
    property x : Int32
    property y : Int32
    property button : MouseButton
    property mod : KeyMod

    def initialize(@x : Int32, @y : Int32, @button : MouseButton, @mod : KeyMod)
    end

    def ==(other : self) : Bool
      @x == other.x && @y == other.y && @button == other.button && @mod == other.mod
    end

    def_hash @x, @y, @button, @mod

    # Returns a string representation of the mouse message.
    def to_s : String
      s = String.build do |io|
        if @mod.contains(ModCtrl)
          io << "ctrl+"
        end
        if @mod.contains(ModAlt)
          io << "alt+"
        end
        if @mod.contains(ModShift)
          io << "shift+"
        end

        str = Input.to_s(@button)
        if str.empty?
          io << "unknown"
        elsif str != "none" # motion events don't have a button
          io << str
        end
      end
      s
    end
  end

  # MouseClickEvent represents a mouse button click event.
  class MouseClickEvent < Event
    include MouseEvent

    getter mouse : Mouse

    def initialize(@mouse : Mouse)
    end

    def initialize(x : Int32, y : Int32, button : MouseButton, mod : KeyMod)
      @mouse = Mouse.new(x, y, button, mod)
    end

    def to_s : String
      @mouse.to_s
    end

    def ==(other : self) : Bool
      @mouse == other.mouse
    end

    def_hash @mouse
  end

  # MouseReleaseEvent represents a mouse button release event.
  class MouseReleaseEvent < Event
    include MouseEvent

    getter mouse : Mouse

    def initialize(@mouse : Mouse)
    end

    def initialize(x : Int32, y : Int32, button : MouseButton, mod : KeyMod)
      @mouse = Mouse.new(x, y, button, mod)
    end

    def to_s : String
      @mouse.to_s
    end

    def ==(other : self) : Bool
      @mouse == other.mouse
    end

    def_hash @mouse
  end

  # MouseWheelEvent represents a mouse wheel message event.
  class MouseWheelEvent < Event
    include MouseEvent

    getter mouse : Mouse

    def initialize(@mouse : Mouse)
    end

    def initialize(x : Int32, y : Int32, button : MouseButton, mod : KeyMod)
      @mouse = Mouse.new(x, y, button, mod)
    end

    def to_s : String
      @mouse.to_s
    end

    def ==(other : self) : Bool
      @mouse == other.mouse
    end

    def_hash @mouse
  end

  # MouseMotionEvent represents a mouse motion event.
  class MouseMotionEvent < Event
    include MouseEvent

    getter mouse : Mouse

    def initialize(@mouse : Mouse)
    end

    def initialize(x : Int32, y : Int32, button : MouseButton, mod : KeyMod)
      @mouse = Mouse.new(x, y, button, mod)
    end

    def to_s : String
      m = @mouse
      if m.button != 0
        m.to_s + "+motion"
      else
        m.to_s + "motion"
      end
    end

    def ==(other : self) : Bool
      @mouse == other.mouse
    end

    def_hash @mouse
  end

  X10_MOUSE_BYTE_OFFSET = 32

  # Parse X10-encoded mouse events; the simplest kind.
  # X10 mouse events look like: ESC [M Cb Cx Cy
  # See: http://www.xfree86.org/current/ctlseqs.html#Mouse%20Tracking
  def self.parse_x10_mouse_event(buf : Bytes) : Event
    v = buf[3..5] # bytes after CSI M
    b = v[0].to_i
    if b >= X10_MOUSE_BYTE_OFFSET
      b -= X10_MOUSE_BYTE_OFFSET
    end

    mod, btn, is_release, is_motion = parse_mouse_button(b)

    # (1,1) is the upper left. We subtract 1 to normalize it to (0,0).
    x = v[1].to_i - X10_MOUSE_BYTE_OFFSET - 1
    y = v[2].to_i - X10_MOUSE_BYTE_OFFSET - 1

    m = Mouse.new(x: x, y: y, button: btn, mod: mod)
    if wheel?(m.button)
      MouseWheelEvent.new(m)
    elsif is_motion
      MouseMotionEvent.new(m)
    elsif is_release
      MouseReleaseEvent.new(m)
    else
      MouseClickEvent.new(m)
    end
  end

  # Parse SGR-encoded mouse events; SGR extended mouse events.
  # SGR mouse events look like: ESC [ < Cb ; Cx ; Cy (M or m)
  # where:
  #   Cb is the encoded button code
  #   Cx is the x-coordinate of the mouse
  #   Cy is the y-coordinate of the mouse
  #   M is for button press, m is for button release
  # https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Extended-coordinates
  def self.parse_sgr_mouse_event(cmd : Int32, params : Array(Int32)) : Event
    x = params.size > 1 ? params[1] : 1
    y = params.size > 2 ? params[2] : 1
    release = (cmd & 0xFF) == 'm'.ord
    b = params.size > 0 ? params[0] : 0
    mod, btn, _, is_motion = parse_mouse_button(b)

    # (1,1) is the upper left. We subtract 1 to normalize it to (0,0).
    x -= 1
    y -= 1

    m = Mouse.new(x: x, y: y, button: btn, mod: mod)

    # Wheel buttons don't have release events
    # Motion can be reported as a release event in some terminals (Windows Terminal)
    if wheel?(m.button)
      MouseWheelEvent.new(m)
    elsif !is_motion && release
      MouseReleaseEvent.new(m)
    elsif is_motion
      MouseMotionEvent.new(m)
    else
      MouseClickEvent.new(m)
    end
  end

  private def self.parse_mouse_button(b : Int32) : {KeyMod, MouseButton, Bool, Bool}
    # mouse bit shifts
    bit_shift = 0b0000_0100
    bit_alt = 0b0000_1000
    bit_ctrl = 0b0001_0000
    bit_motion = 0b0010_0000
    bit_wheel = 0b0100_0000
    bit_add = 0b1000_0000 # additional buttons 8-11

    bits_mask = 0b0000_0011

    # Modifiers
    mod = KeyMod::None
    if b & bit_alt != 0
      mod |= ModAlt
    end
    if b & bit_ctrl != 0
      mod |= ModCtrl
    end
    if b & bit_shift != 0
      mod |= ModShift
    end

    btn = MouseNone
    is_release = false
    is_motion = false

    if b & bit_add != 0
      btn = MouseBackward + (b & bits_mask).to_u8
    elsif b & bit_wheel != 0
      btn = MouseWheelUp + (b & bits_mask).to_u8
    else
      btn = MouseLeft + (b & bits_mask).to_u8
      # X10 reports a button release as 0b0000_0011 (3)
      if b & bits_mask == bits_mask
        btn = MouseNone
        is_release = true
      end
    end

    # Motion bit doesn't get reported for wheel events.
    if b & bit_motion != 0 && !wheel?(btn)
      is_motion = true
    end

    {mod, btn, is_release, is_motion}
  end

  private def self.wheel?(btn : MouseButton) : Bool
    btn >= MouseWheelUp && btn <= MouseWheelRight
  end
end
