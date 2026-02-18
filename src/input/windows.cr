# Windows console API constants and types.
# Ported from github.com/charmbracelet/x/windows
module Input
  module Windows
    # Virtual Key codes
    # https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
    VK_LBUTTON             = 0x01_u16
    VK_RBUTTON             = 0x02_u16
    VK_CANCEL              = 0x03_u16
    VK_MBUTTON             = 0x04_u16
    VK_XBUTTON1            = 0x05_u16
    VK_XBUTTON2            = 0x06_u16
    VK_BACK                = 0x08_u16
    VK_TAB                 = 0x09_u16
    VK_CLEAR               = 0x0C_u16
    VK_RETURN              = 0x0D_u16
    VK_SHIFT               = 0x10_u16
    VK_CONTROL             = 0x11_u16
    VK_MENU                = 0x12_u16
    VK_PAUSE               = 0x13_u16
    VK_CAPITAL             = 0x14_u16
    VK_KANA                = 0x15_u16
    VK_HANGEUL             = 0x15_u16
    VK_HANGUL              = 0x15_u16
    VK_IME_ON              = 0x16_u16
    VK_JUNJA               = 0x17_u16
    VK_FINAL               = 0x18_u16
    VK_HANJA               = 0x19_u16
    VK_KANJI               = 0x19_u16
    VK_IME_OFF             = 0x1A_u16
    VK_ESCAPE              = 0x1B_u16
    VK_CONVERT             = 0x1C_u16
    VK_NONCONVERT          = 0x1D_u16
    VK_ACCEPT              = 0x1E_u16
    VK_MODECHANGE          = 0x1F_u16
    VK_SPACE               = 0x20_u16
    VK_PRIOR               = 0x21_u16
    VK_NEXT                = 0x22_u16
    VK_END                 = 0x23_u16
    VK_HOME                = 0x24_u16
    VK_LEFT                = 0x25_u16
    VK_UP                  = 0x26_u16
    VK_RIGHT               = 0x27_u16
    VK_DOWN                = 0x28_u16
    VK_SELECT              = 0x29_u16
    VK_PRINT               = 0x2A_u16
    VK_EXECUTE             = 0x2B_u16
    VK_SNAPSHOT            = 0x2C_u16
    VK_INSERT              = 0x2D_u16
    VK_DELETE              = 0x2E_u16
    VK_HELP                = 0x2F_u16
    VK_LWIN                = 0x5B_u16
    VK_RWIN                = 0x5C_u16
    VK_APPS                = 0x5D_u16
    VK_SLEEP               = 0x5F_u16
    VK_NUMPAD0             = 0x60_u16
    VK_NUMPAD1             = 0x61_u16
    VK_NUMPAD2             = 0x62_u16
    VK_NUMPAD3             = 0x63_u16
    VK_NUMPAD4             = 0x64_u16
    VK_NUMPAD5             = 0x65_u16
    VK_NUMPAD6             = 0x66_u16
    VK_NUMPAD7             = 0x67_u16
    VK_NUMPAD8             = 0x68_u16
    VK_NUMPAD9             = 0x69_u16
    VK_MULTIPLY            = 0x6A_u16
    VK_ADD                 = 0x6B_u16
    VK_SEPARATOR           = 0x6C_u16
    VK_SUBTRACT            = 0x6D_u16
    VK_DECIMAL             = 0x6E_u16
    VK_DIVIDE              = 0x6F_u16
    VK_F1                  = 0x70_u16
    VK_F2                  = 0x71_u16
    VK_F3                  = 0x72_u16
    VK_F4                  = 0x73_u16
    VK_F5                  = 0x74_u16
    VK_F6                  = 0x75_u16
    VK_F7                  = 0x76_u16
    VK_F8                  = 0x77_u16
    VK_F9                  = 0x78_u16
    VK_F10                 = 0x79_u16
    VK_F11                 = 0x7A_u16
    VK_F12                 = 0x7B_u16
    VK_F13                 = 0x7C_u16
    VK_F14                 = 0x7D_u16
    VK_F15                 = 0x7E_u16
    VK_F16                 = 0x7F_u16
    VK_F17                 = 0x80_u16
    VK_F18                 = 0x81_u16
    VK_F19                 = 0x82_u16
    VK_F20                 = 0x83_u16
    VK_F21                 = 0x84_u16
    VK_F22                 = 0x85_u16
    VK_F23                 = 0x86_u16
    VK_F24                 = 0x87_u16
    VK_NUMLOCK             = 0x90_u16
    VK_SCROLL              = 0x91_u16
    VK_OEM_NEC_EQUAL       = 0x92_u16
    VK_OEM_FJ_JISHO        = 0x92_u16
    VK_OEM_FJ_MASSHOU      = 0x93_u16
    VK_OEM_FJ_TOUROKU      = 0x94_u16
    VK_OEM_FJ_LOYA         = 0x95_u16
    VK_OEM_FJ_ROYA         = 0x96_u16
    VK_LSHIFT              = 0xA0_u16
    VK_RSHIFT              = 0xA1_u16
    VK_LCONTROL            = 0xA2_u16
    VK_RCONTROL            = 0xA3_u16
    VK_LMENU               = 0xA4_u16
    VK_RMENU               = 0xA5_u16
    VK_BROWSER_BACK        = 0xA6_u16
    VK_BROWSER_FORWARD     = 0xA7_u16
    VK_BROWSER_REFRESH     = 0xA8_u16
    VK_BROWSER_STOP        = 0xA9_u16
    VK_BROWSER_SEARCH      = 0xAA_u16
    VK_BROWSER_FAVORITES   = 0xAB_u16
    VK_BROWSER_HOME        = 0xAC_u16
    VK_VOLUME_MUTE         = 0xAD_u16
    VK_VOLUME_DOWN         = 0xAE_u16
    VK_VOLUME_UP           = 0xAF_u16
    VK_MEDIA_NEXT_TRACK    = 0xB0_u16
    VK_MEDIA_PREV_TRACK    = 0xB1_u16
    VK_MEDIA_STOP          = 0xB2_u16
    VK_MEDIA_PLAY_PAUSE    = 0xB3_u16
    VK_LAUNCH_MAIL         = 0xB4_u16
    VK_LAUNCH_MEDIA_SELECT = 0xB5_u16
    VK_LAUNCH_APP1         = 0xB6_u16
    VK_LAUNCH_APP2         = 0xB7_u16
    VK_OEM_1               = 0xBA_u16
    VK_OEM_PLUS            = 0xBB_u16
    VK_OEM_COMMA           = 0xBC_u16
    VK_OEM_MINUS           = 0xBD_u16
    VK_OEM_PERIOD          = 0xBE_u16
    VK_OEM_2               = 0xBF_u16
    VK_OEM_3               = 0xC0_u16
    VK_OEM_4               = 0xDB_u16
    VK_OEM_5               = 0xDC_u16
    VK_OEM_6               = 0xDD_u16
    VK_OEM_7               = 0xDE_u16
    VK_OEM_8               = 0xDF_u16
    VK_OEM_AX              = 0xE1_u16
    VK_OEM_102             = 0xE2_u16
    VK_ICO_HELP            = 0xE3_u16
    VK_ICO_00              = 0xE4_u16
    VK_PROCESSKEY          = 0xE5_u16
    VK_ICO_CLEAR           = 0xE6_u16
    VK_OEM_RESET           = 0xE9_u16
    VK_OEM_JUMP            = 0xEA_u16
    VK_OEM_PA1             = 0xEB_u16
    VK_OEM_PA2             = 0xEC_u16
    VK_OEM_PA3             = 0xED_u16
    VK_OEM_WSCTRL          = 0xEE_u16
    VK_OEM_CUSEL           = 0xEF_u16
    VK_OEM_ATTN            = 0xF0_u16
    VK_OEM_FINISH          = 0xF1_u16
    VK_OEM_COPY            = 0xF2_u16
    VK_OEM_AUTO            = 0xF3_u16
    VK_OEM_ENLW            = 0xF4_u16
    VK_OEM_BACKTAB         = 0xF5_u16
    VK_ATTN                = 0xF6_u16
    VK_CRSEL               = 0xF7_u16
    VK_EXSEL               = 0xF8_u16
    VK_EREOF               = 0xF9_u16
    VK_PLAY                = 0xFA_u16
    VK_ZOOM                = 0xFB_u16
    VK_NONAME              = 0xFC_u16
    VK_PA1                 = 0xFD_u16
    VK_OEM_CLEAR           = 0xFE_u16

    # Mouse button constants.
    FROM_LEFT_1ST_BUTTON_PRESSED = 0x0001_u32
    RIGHTMOST_BUTTON_PRESSED     = 0x0002_u32
    FROM_LEFT_2ND_BUTTON_PRESSED = 0x0004_u32
    FROM_LEFT_3RD_BUTTON_PRESSED = 0x0008_u32
    FROM_LEFT_4TH_BUTTON_PRESSED = 0x0010_u32

    # Control key state constraints.
    CAPSLOCK_ON        = 0x0080_u32
    ENHANCED_KEY       = 0x0100_u32
    LEFT_ALT_PRESSED   = 0x0002_u32
    LEFT_CTRL_PRESSED  = 0x0008_u32
    NUMLOCK_ON         = 0x0020_u32
    RIGHT_ALT_PRESSED  = 0x0001_u32
    RIGHT_CTRL_PRESSED = 0x0004_u32
    SCROLLLOCK_ON      = 0x0040_u32
    SHIFT_PRESSED      = 0x0010_u32

    # Mouse event record event flags.
    MOUSE_MOVED    = 0x0001_u32
    DOUBLE_CLICK   = 0x0002_u32
    MOUSE_WHEELED  = 0x0004_u32
    MOUSE_HWHEELED = 0x0008_u32

    # Input Record Event Types
    FOCUS_EVENT              = 0x0010_u16
    KEY_EVENT                = 0x0001_u16
    MENU_EVENT               = 0x0008_u16
    MOUSE_EVENT              = 0x0002_u16
    WINDOW_BUFFER_SIZE_EVENT = 0x0004_u16

    # Structs corresponding to Windows console API records
    record Coord, x : Int16, y : Int16
    record KeyEventRecord,
      key_down : Bool,
      repeat_count : UInt16,
      virtual_key_code : UInt16,
      virtual_scan_code : UInt16,
      char : Char,
      control_key_state : UInt32

    record MouseEventRecord,
      mouse_position : Coord,
      button_state : UInt32,
      control_key_state : UInt32,
      event_flags : UInt32

    record FocusEventRecord,
      set_focus : Bool

    record WindowBufferSizeRecord,
      size : Coord

    record MenuEventRecord,
      command_id : UInt32

    record InputRecord,
      event_type : UInt16,
      event : StaticArray(UInt8, 16) do
      # Returns the event as a KeyEventRecord.
      # Assumes event_type is KEY_EVENT.
      def key_event : KeyEventRecord
        ptr = event.to_unsafe.as(Pointer(UInt8))
        KeyEventRecord.new(
          key_down: ptr.as(Pointer(UInt32)).value != 0,
          repeat_count: (ptr + 4).as(Pointer(UInt16)).value,
          virtual_key_code: (ptr + 6).as(Pointer(UInt16)).value,
          virtual_scan_code: (ptr + 8).as(Pointer(UInt16)).value,
          char: (ptr + 10).as(Pointer(UInt16)).value.chr,
          control_key_state: (ptr + 12).as(Pointer(UInt32)).value
        )
      end

      # Returns the event as a MouseEventRecord.
      # Assumes event_type is MOUSE_EVENT.
      def mouse_event : MouseEventRecord
        ptr = event.to_unsafe.as(Pointer(UInt8))
        MouseEventRecord.new(
          mouse_position: Coord.new(
            x: ptr.as(Pointer(Int16)).value,
            y: (ptr + 2).as(Pointer(Int16)).value
          ),
          button_state: (ptr + 4).as(Pointer(UInt32)).value,
          control_key_state: (ptr + 8).as(Pointer(UInt32)).value,
          event_flags: (ptr + 12).as(Pointer(UInt32)).value
        )
      end

      # Returns the event as a WindowBufferSizeRecord.
      # Assumes event_type is WINDOW_BUFFER_SIZE_EVENT.
      def window_buffer_size_event : WindowBufferSizeRecord
        ptr = event.to_unsafe.as(Pointer(UInt8))
        WindowBufferSizeRecord.new(
          size: Coord.new(
            x: ptr.as(Pointer(Int16)).value,
            y: (ptr + 2).as(Pointer(Int16)).value
          )
        )
      end

      # Returns the event as a FocusEventRecord.
      # Assumes event_type is FOCUS_EVENT.
      def focus_event : FocusEventRecord
        FocusEventRecord.new(set_focus: event[0] != 0)
      end

      # Returns the event as a MenuEventRecord.
      # Assumes event_type is MENU_EVENT.
      def menu_event : MenuEventRecord
        ptr = event.to_unsafe.as(Pointer(UInt8))
        MenuEventRecord.new(command_id: ptr.as(Pointer(UInt32)).value)
      end
    end

    {% if flag?(:windows) %}
      # Handle type alias for Windows console handles.
      alias Handle = LibC::HANDLE
      STD_INPUT_HANDLE      = 0xFFFF_FFF6_u32
      ENABLE_WINDOW_INPUT   =      0x0008_u32
      ENABLE_MOUSE_INPUT    =      0x0010_u32
      ENABLE_EXTENDED_FLAGS =      0x0080_u32

      # Kernel32 library bindings for console input.
      @[Link("kernel32")]
      lib Kernel32
        # https://learn.microsoft.com/en-us/windows/console/getstdhandle
        fun GetStdHandle(stdhandle : UInt32) : Handle

        # https://learn.microsoft.com/en-us/windows/console/getconsolemode
        fun GetConsoleMode(console : Handle, mode : UInt32*) : Bool

        # https://learn.microsoft.com/en-us/windows/console/setconsolemode
        fun SetConsoleMode(console : Handle, mode : UInt32) : Bool

        # https://docs.microsoft.com/en-us/windows/console/readconsoleinput
        fun ReadConsoleInputW(
          console : Handle,
          buf : InputRecord*,
          toread : UInt32,
          read : UInt32*,
        ) : Bool

        # https://docs.microsoft.com/en-us/windows/console/peekconsoleinput
        fun PeekConsoleInputW(
          console : Handle,
          buf : InputRecord*,
          toread : UInt32,
          read : UInt32*,
        ) : Bool

        # https://docs.microsoft.com/en-us/windows/console/getnumberofconsoleinputevents
        fun GetNumberOfConsoleInputEvents(
          console : Handle,
          numevents : UInt32*,
        ) : Bool

        # https://docs.microsoft.com/en-us/windows/console/flushconsoleinputbuffer
        fun FlushConsoleInputBuffer(console : Handle) : Bool

        # https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-readfile
        fun ReadFile(
          file : Handle,
          buffer : Void*,
          bytes_to_read : UInt32,
          bytes_read : UInt32*,
          overlapped : Void*,
        ) : Bool

        # https://learn.microsoft.com/en-us/windows/win32/fileio/cancelioex-func
        fun CancelIoEx(file : Handle, overlapped : Void*) : Bool

        # https://learn.microsoft.com/en-us/windows/win32/fileio/cancelio
        fun CancelIo(file : Handle) : Bool
      end

      def self.get_std_handle(stdhandle : UInt32) : Handle
        handle = Kernel32.GetStdHandle(stdhandle)
        raise RuntimeError.new("GetStdHandle failed") if handle.null?
        handle
      end

      def self.get_console_mode(console : Handle) : UInt32
        mode = uninitialized UInt32
        if Kernel32.GetConsoleMode(console, pointerof(mode))
          mode
        else
          raise RuntimeError.new("GetConsoleMode failed")
        end
      end

      def self.set_console_mode(console : Handle, mode : UInt32) : Nil
        unless Kernel32.SetConsoleMode(console, mode)
          raise RuntimeError.new("SetConsoleMode failed")
        end
      end

      # Reads input records from the console.
      def self.read_console_input(console : Handle, records : Slice(InputRecord)) : UInt32
        read = uninitialized UInt32
        if Kernel32.ReadConsoleInputW(console, records.to_unsafe, records.size, pointerof(read))
          read
        else
          raise RuntimeError.new("ReadConsoleInput failed")
        end
      end

      # Peeks at console input records without removing them.
      def self.peek_console_input(console : Handle, records : Slice(InputRecord)) : UInt32
        read = uninitialized UInt32
        if Kernel32.PeekConsoleInputW(console, records.to_unsafe, records.size, pointerof(read))
          read
        else
          raise RuntimeError.new("PeekConsoleInput failed")
        end
      end

      # Gets the number of console input events waiting.
      def self.get_number_of_console_input_events(console : Handle) : UInt32
        numevents = uninitialized UInt32
        if Kernel32.GetNumberOfConsoleInputEvents(console, pointerof(numevents))
          numevents
        else
          raise RuntimeError.new("GetNumberOfConsoleInputEvents failed")
        end
      end

      # Flushes the console input buffer.
      def self.flush_console_input_buffer(console : Handle) : Nil
        unless Kernel32.FlushConsoleInputBuffer(console)
          raise RuntimeError.new("FlushConsoleInputBuffer failed")
        end
      end

      def self.read_file(handle : Handle, slice : Bytes) : UInt32
        read = uninitialized UInt32
        if Kernel32.ReadFile(handle, slice.to_unsafe.as(Void*), slice.size.to_u32, pointerof(read), Pointer(Void).null)
          read
        else
          raise RuntimeError.new("ReadFile failed")
        end
      end

      def self.cancel_io_ex(handle : Handle) : Bool
        Kernel32.CancelIoEx(handle, Pointer(Void).null)
      end

      def self.cancel_io(handle : Handle) : Bool
        Kernel32.CancelIo(handle)
      end
    {% end %}
  end
end
