module Input
  # Event represents a terminal event.
  abstract class Event
  end

  # UnknownEvent represents an unknown event.
  class UnknownEvent < Event
    getter value : String

    def initialize(@value : String)
    end

    # Returns a string representation of the unknown event.
    def to_s : String
      "\"#{@value}\""
    end

    def ==(other : self) : Bool
      @value == other.value
    end

    def_hash @value
  end

  # MultiEvent represents multiple messages event.
  class MultiEvent < Event
    getter events : Array(Event)

    def initialize(@events : Array(Event))
    end

    # Returns a string representation of the multiple messages event.
    def to_s : String
      @events.join("\n")
    end

    def ==(other : self) : Bool
      @events == other.events
    end

    def_hash @events
  end

  # WindowSizeEvent is used to report the terminal size. Note that Windows does
  # not have support for reporting resizes via SIGWINCH signals and relies on
  # the Windows Console API to report window size changes.
  class WindowSizeEvent < Event
    getter width : Int32
    getter height : Int32

    def initialize(@width : Int32, @height : Int32)
    end

    def ==(other : self) : Bool
      @width == other.width && @height == other.height
    end

    def_hash @width, @height
  end

  # WindowOpEvent is a window operation (XTWINOPS) report event. This is used to
  # report various window operations such as reporting the window size or cell
  # size.
  class WindowOpEvent < Event
    getter op : Int32
    getter args : Array(Int32)

    def initialize(@op : Int32, @args : Array(Int32))
    end

    def ==(other : self) : Bool
      @op == other.op && @args == other.args
    end

    def_hash @op, @args
  end

  # FocusEvent is emitted when the terminal window gains focus.
  class FocusEvent < Event
    def ==(other : self) : Bool
      true
    end

    def_hash
  end

  # BlurEvent is emitted when the terminal window loses focus.
  class BlurEvent < Event
    def ==(other : self) : Bool
      true
    end

    def_hash
  end

  # PasteStartEvent indicates the start of bracketed paste.
  class PasteStartEvent < Event
    def ==(other : self) : Bool
      true
    end

    def_hash
  end

  # PasteEndEvent indicates the end of bracketed paste.
  class PasteEndEvent < Event
    def ==(other : self) : Bool
      true
    end

    def_hash
  end

  # CursorPositionEvent reports the cursor position.
  class CursorPositionEvent < Event
    getter x : Int32
    getter y : Int32

    def initialize(@x : Int32, @y : Int32)
    end

    def ==(other : self) : Bool
      @x == other.x && @y == other.y
    end

    def_hash @x, @y
  end

  # ModeReportEvent reports a terminal mode change.
  class ModeReportEvent < Event
    getter mode : Int32
    getter value : Int32

    def initialize(@mode : Int32, @value : Int32)
    end

    def ==(other : self) : Bool
      @mode == other.mode && @value == other.value
    end

    def_hash @mode, @value
  end

  # ModifyOtherKeysEvent reports XTerm modifyOtherKeys mode.
  class ModifyOtherKeysEvent < Event
    getter value : Int32

    def initialize(@value : Int32)
    end

    def ==(other : self) : Bool
      @value == other.value
    end

    def_hash @value
  end

  # KittyEnhancementsEvent reports Kitty keyboard enhancements.
  class KittyEnhancementsEvent < Event
    getter flags : Int32

    def initialize(@flags : Int32)
    end

    def ==(other : self) : Bool
      @flags == other.flags
    end

    def_hash @flags
  end
end
