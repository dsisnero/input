module Input
  private def self.hex_decode(str : String) : Bytes?
    return Bytes.empty if str.empty?
    if str.size % 2 != 0
      return nil
    end
    bytes = Bytes.new(str.size // 2)
    i = 0
    while i < str.size
      high = str[i].to_i?(16)
      low = str[i + 1].to_i?(16)
      if high.nil? || low.nil?
        return nil
      end
      bytes[i // 2] = (high << 4 | low).to_u8
      i += 2
    end
    bytes
  end

  # parse_termcap parses a Termcap/Terminfo response (XTGETTCAP).
  def self.parse_termcap(data : Bytes) : CapabilityEvent
    # XTGETTCAP
    if data.size == 0
      return CapabilityEvent.new("")
    end

    str = String.new(data)
    tc = String::Builder.new
    str.split(';') do |segment|
      parts = segment.split('=', 2)
      if parts.empty?
        return CapabilityEvent.new("")
      end

      name_hex = parts[0]
      name = hex_decode(name_hex)
      if name.nil? || name.empty?
        next
      end

      value = Bytes.empty
      if parts.size > 1
        value_hex = parts[1]
        decoded = hex_decode(value_hex)
        next if decoded.nil?
        value = decoded
      end

      if tc.bytesize > 0
        tc << ';'
      end
      tc << String.new(name)
      if !value.empty?
        tc << '='
        tc << String.new(value)
      end
    end

    CapabilityEvent.new(tc.to_s)
  end
end
