require "../spec_helper"

module Input
  def self.random_interleaved_data(seed : Int64, min_length : Int32) : Bytes
    rng = Random.new(seed)
    seqs = Input.build_keys_table(FlagTerminfo, "dumb").keys.sort
    data = [] of UInt8

    while data.size < min_length
      alt = rng.rand(2) == 1
      kind = rng.rand(3)
      if kind == 0
        data << 0x1b_u8 if alt
        data << 0x01_u8 # ctrl+a
      else
        seq = seqs[rng.rand(seqs.size)]
        # Avoid double-alt prefixes from map entries that are already alt/meta.
        if alt && !seq.starts_with?("\e")
          data << 0x1b_u8
        end
        data.concat(seq.to_slice)
      end
    end

    Slice.new(data.to_unsafe, data.size)
  end

  describe Parser do
    it "matches Go fuzz seeds with non-zero widths" do
      parser = Parser.new
      seeds = Input.build_keys_table(FlagTerminfo, "dumb").keys
      seeds += [
        "\e]52;?\a",                      # OSC 52
        "\e]11;rgb:0000/0000/0000\e\\",   # OSC 11
        "\eP>|charm terminal(0.1.2)\e\\", # DCS (XTVERSION)
        "\e_Gi=123\e\\",                  # APC (kitty graphics)
      ]

      seeds.each do |seq|
        n, _ = parser.parse_sequence(seq.to_slice)
        next if seq.empty?
        n.should be > 0
      end
    end

    it "does not stall on randomized interleaved control/sequence input" do
      parser = Parser.new
      data = Input.random_interleaved_data(123_i64, 10_000)
      i = 0
      while i < data.size
        n, _ = parser.parse_sequence(data[i..])
        n.should be > 0
        i += n
      end
    end
  end
end
