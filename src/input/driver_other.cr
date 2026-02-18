module Input
  {% unless flag?(:windows) %}
    class Parser
      # parse_win32_input_key_event parses a Win32 input key events. This function is
      # only available on Windows.
      def parse_win32_input_key_event(state : Win32InputState, vkey : UInt16, scan : UInt16, char : Char, keydown : Bool, cks : UInt32, repeat : UInt16) : Event?
        nil
      end
    end
  {% end %}
end
