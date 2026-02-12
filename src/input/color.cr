require "ansi"

module Input
  # RGBA represents a 32-bit color with red, green, blue, and alpha channels.
  struct RGBA
    getter r : UInt8
    getter g : UInt8
    getter b : UInt8
    getter a : UInt8

    def initialize(@r : UInt8, @g : UInt8, @b : UInt8, @a : UInt8 = 255_u8)
    end

    def ==(other : self) : Bool
      @r == other.r && @g == other.g && @b == other.b && @a == other.a
    end

    def_hash @r, @g, @b, @a
  end

  # ForegroundColorEvent represents a foreground color event. This event is
  # emitted when the terminal requests the terminal foreground color using
  # [Ansi.request_foreground_color].
  class ForegroundColorEvent < Event
    getter color : RGBA

    def initialize(@color : RGBA)
    end

    def ==(other : self) : Bool
      @color == other.color
    end

    def_hash @color
  end

  # BackgroundColorEvent represents a background color event. This event is
  # emitted when the terminal requests the terminal background color using
  # [Ansi.request_background_color].
  class BackgroundColorEvent < Event
    getter color : RGBA

    def initialize(@color : RGBA)
    end

    def ==(other : self) : Bool
      @color == other.color
    end

    def_hash @color
  end

  # CursorColorEvent represents a cursor color change event. This event is
  # emitted when the program requests the terminal cursor color using
  # [Ansi.request_cursor_color].
  class CursorColorEvent < Event
    getter color : RGBA

    def initialize(@color : RGBA)
    end

    def ==(other : self) : Bool
      @color == other.color
    end

    def_hash @color
  end
end
