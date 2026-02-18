require "cancel_reader"

module Input
  {% if flag?(:windows) %}
    class ConInputReader < CancelReader::Reader
      getter conin : Windows::Handle

      def initialize(@conin : Windows::Handle, @original_mode : UInt32)
        @canceled = false
        @lock = Mutex.new
      end

      def canceled? : Bool
        @lock.synchronize { @canceled }
      end

      def cancel : Bool
        @lock.synchronize { @canceled = true }
        Windows.cancel_io_ex(@conin) || Windows.cancel_io(@conin)
      end

      def close : Nil
        return if @original_mode == 0
        Windows.set_console_mode(@conin, @original_mode)
      end

      def read(slice : Bytes) : Int32
        raise CancelReader::ErrCanceled if canceled?
        begin
          n = Windows.read_file(@conin, slice)
          raise CancelReader::ErrCanceled if canceled?
          n.to_i
        rescue ex
          raise CancelReader::ErrCanceled if canceled?
          raise ex
        end
      end
    end
  {% end %}

  def self.new_cancelreader(r : IO, flags : Int32) : CancelReader::Reader
    fallback = -> { CancelReader.new_reader(r) }

    {% if flag?(:windows) %}
      fd_io = r.as?(IO::FileDescriptor)
      return fallback.call unless fd_io && fd_io.fd == STDIN.fd

      begin
        # If stdin is not a console handle, fall back to generic behavior.
        Windows.get_console_mode(Pointer(Void).new(fd_io.fd.to_u64))
      rescue
        return fallback.call
      end

      begin
        conin = Windows.get_std_handle(Windows::STD_INPUT_HANDLE)
        Windows.flush_console_input_buffer(conin)
        original_mode = prepare_console(conin, flags)
        return ConInputReader.new(conin, original_mode)
      rescue
        return fallback.call
      end
    {% else %}
      fallback.call
    {% end %}
  end

  {% if flag?(:windows) %}
    private def self.prepare_console(input : Windows::Handle, flags : Int32) : UInt32
      original_mode = Windows.get_console_mode(input)
      mode = Windows::ENABLE_WINDOW_INPUT | Windows::ENABLE_EXTENDED_FLAGS
      mode |= Windows::ENABLE_MOUSE_INPUT if (flags & FlagMouseMode) != 0
      Windows.set_console_mode(input, mode)
      original_mode
    end
  {% end %}
end
