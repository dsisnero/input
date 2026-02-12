module Input
  # ClipboardSelection represents a clipboard selection. The most common
  # clipboard selections are "system" and "primary" and selections.
  alias ClipboardSelection = UInt8

  # Clipboard selections.
  SystemClipboard  = 'c'.ord.to_u8 # ASCII 'c'
  PrimaryClipboard = 'p'.ord.to_u8 # ASCII 'p'

  # ClipboardEvent is a clipboard read message event. This message is emitted when
  # a terminal receives an OSC52 clipboard read message event.
  class ClipboardEvent < Event
    getter content : String
    getter selection : ClipboardSelection

    def initialize(@content : String, @selection : ClipboardSelection)
    end

    # Returns the string representation of the clipboard message.
    def to_s : String
      @content
    end

    def ==(other : self) : Bool
      @content == other.content && @selection == other.selection
    end

    def_hash @content, @selection
  end
end
