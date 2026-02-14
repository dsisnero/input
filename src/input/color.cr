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
    getter color : RGBA?

    def initialize(@color : RGBA? = nil)
    end

    def to_s : String
      Input.color_to_hex(@color)
    end

    def dark? : Bool
      Input.dark_color?(@color)
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
    getter color : RGBA?

    def initialize(@color : RGBA? = nil)
    end

    def to_s : String
      Input.color_to_hex(@color)
    end

    def dark? : Bool
      Input.dark_color?(@color)
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
    getter color : RGBA?

    def initialize(@color : RGBA? = nil)
    end

    def to_s : String
      Input.color_to_hex(@color)
    end

    def dark? : Bool
      Input.dark_color?(@color)
    end

    def ==(other : self) : Bool
      @color == other.color
    end

    def_hash @color
  end

  private def self.shift(x : UInt32) : UInt32
    x > 0xff ? x >> 8 : x
  end

  private def self.get_max_min(a : Float64, b : Float64, c : Float64) : Tuple(Float64, Float64)
    if a > b
      ma = a
      mi = b
    else
      ma = b
      mi = a
    end
    if c > ma
      ma = c
    elsif c < mi
      mi = c
    end
    {ma, mi}
  end

  private def self.round(x : Float64) : Float64
    (x * 1000).round / 1000
  end

  # rgb_to_hsl converts an RGB triple to an HSL triple.
  private def self.rgb_to_hsl(r : UInt8, g : UInt8, b : UInt8) : Tuple(Float64, Float64, Float64)
    # convert uint32 pre-multiplied value to uint8
    # The r,g,b values are divided by 255 to change the range from 0..255 to 0..1:
    r_not = r.to_f / 255
    g_not = g.to_f / 255
    b_not = b.to_f / 255
    c_max, c_min = get_max_min(r_not, g_not, b_not)
    delta = c_max - c_min
    # Lightness calculation:
    l = (c_max + c_min) / 2
    # Hue and Saturation Calculation:
    if delta == 0
      h = 0.0
      s = 0.0
    else
      case c_max
      when r_not
        h = 60 * ((g_not - b_not) / delta % 6)
      when g_not
        h = 60 * (((b_not - r_not) / delta) + 2)
      when b_not
        h = 60 * (((r_not - g_not) / delta) + 4)
      else
        h = 0.0
      end
      if h < 0
        h += 360
      end
      s = delta / (1 - (2 * l - 1).abs)
    end
    {h, round(s), round(l)}
  end

  def self.color_to_hex(color : RGBA?) : String
    return "" if color.nil? || color.a == 0
    "#%02x%02x%02x" % {shift(color.r.to_u32), shift(color.g.to_u32), shift(color.b.to_u32)}
  end

  def self.dark_color?(color : RGBA?) : Bool
    return true if color.nil? || color.a == 0
    _, _, l = rgb_to_hsl(color.r, color.g, color.b)
    l < 0.5
  end
end
