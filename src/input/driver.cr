require "cancel_reader"
require "./key"
require "./parse"
require "./table"
require "./mod"

{% if flag?(:windows) %}
  require "./cancelreader_windows"
{% else %}
  require "./cancelreader_other"
{% end %}

module Input
  # Logger is a simple logger interface.
  module Logger
    abstract def printf(format : String, *args)
  end

  # win32InputState is a state machine for parsing key events from the Windows
  # Console API into escape sequences and utf8 runes, and keeps track of the last
  # control key state to determine modifier key changes. It also keeps track of
  # the last mouse button state and window size changes to determine which mouse
  # buttons were released and to prevent multiple size events from firing.
  struct Win32InputState
    property ansi_buf : StaticArray(UInt8, 256)
    property ansi_idx : Int32
    property utf16_buf : StaticArray(Char, 2)
    property utf16_half : Bool
    property last_cks : UInt32        # the last control key state for the previous event
    property last_mouse_btns : UInt32 # the last mouse button state for the previous event
    property last_winsize_x : Int16   # the last window size for the previous event to prevent multiple size events from firing
    property last_winsize_y : Int16

    def initialize
      @ansi_buf = uninitialized StaticArray(UInt8, 256)
      @ansi_idx = 0
      @utf16_buf = uninitialized StaticArray(Char, 2)
      @utf16_half = false
      @last_cks = 0_u32
      @last_mouse_btns = 0_u32
      @last_winsize_x = 0_i16
      @last_winsize_y = 0_i16
    end
  end

  # Reader represents an input event reader. It reads input events and parses
  # escape sequences from the terminal input buffer and translates them into
  # human-readable events.
  class Reader
    @rd : CancelReader::Reader?
    @table : Hash(String, Key)?
    @term : String?
    @paste : Array(UInt8)?
    @buf : StaticArray(UInt8, 256)
    @key_state : Win32InputState
    @parser : Parser?
    @logger : Logger?

    # NewReader returns a new input event reader. The reader reads input events
    # from the terminal and parses escape sequences into human-readable events. It
    # supports reading Terminfo databases. See [Parser] for more information.
    #
    # Example:
    #
    # r, _ = Input.new_reader(STDIN, ENV["TERM"]?, 0)
    # events, _ = r.read_events
    # events.each do |ev|
    #   puts ev
    # end
    def self.new_reader(r : IO, term_type : String, flags : Int32) : Reader
      d = new
      cr = Input.new_cancelreader(r, flags)
      d.rd = cr
      d.table = Input.build_keys_table(flags, term_type)
      d.term = term_type
      d.parser = Parser.new(flags)
      d
    end

    # SetLogger sets a logger for the reader.
    def set_logger(l : Logger)
      @logger = l
    end

    # Read implements IO::Reader.
    def read(slice : Bytes) : Int32
      @rd.not_nil!.read(slice)
    end

    # Cancel cancels the underlying reader.
    def cancel : Bool
      @rd.not_nil!.cancel
    end

    # Close closes the underlying reader.
    def close : Nil
      @rd.not_nil!.close
    end

    # ReadEvents reads input events from the terminal.
    #
    # It reads the events available in the input buffer and returns them.
    def read_events : Array(Event)
      {% if flag?(:windows) %}
        if con_reader = @rd.as?(ConInputReader)
          return handle_con_input(con_reader)
        end
      {% end %}
      read_events_fallback
    end

    private def read_events_fallback : Array(Event)
      nb = @rd.not_nil!.read(@buf.to_slice)
      events = [] of Event
      buf = @buf.to_slice[0, nb]

      # Lookup table first
      if buf.size > 0 && buf[0] == 0x1b
        key = String.new(buf)
        if k = @table.not_nil![key]?
          @logger.try &.printf("input: %q", key)
          events << KeyPressEvent.new(k)
          return events
        end
      end

      i = 0
      while i < buf.size
        nb, ev = @parser.not_nil!.parse_sequence(buf[i..])
        @logger.try &.printf("input: %q", buf[i, nb])

        # Handle bracketed-paste
        if paste = @paste
          unless ev.is_a?(PasteEndEvent)
            paste << buf[i]
            i += 1
            next
          end
        end

        case ev
        when UnknownEvent
          # If the sequence is not recognized by the parser, try looking it up.
          sub = String.new(buf[i, nb])
          if k = @table.not_nil![sub]?
            ev = KeyPressEvent.new(k)
          end
        when PasteStartEvent
          @paste = [] of UInt8
        when PasteEndEvent
          # Decode the captured data into runes.
          if paste = @paste
            # Convert bytes to string, filtering out replacement characters
            str = String.new(Slice.new(paste.to_unsafe, paste.size))
            # Remove any replacement characters (U+FFFD) from invalid UTF-8 sequences
            str = str.gsub('\uFFFD', "")
            events << PasteEvent.new(str)
            @paste = nil # reset the buffer
          end
        when nil
          i += 1
          next
        end

        if ev.is_a?(MultiEvent)
          events.concat(ev.events)
        else
          events << ev
        end
        i += nb
      end

      events
    end

    protected def rd=(cr : CancelReader::Reader)
      @rd = cr
    end

    protected def table=(table : Hash(String, Key))
      @table = table
    end

    protected def term=(term : String)
      @term = term
    end

    protected def parser=(parser : Parser)
      @parser = parser
    end

    private def initialize
      @paste = nil
      @buf = uninitialized StaticArray(UInt8, 256)
      @key_state = Win32InputState.new
      @logger = nil
    end
  end
end
