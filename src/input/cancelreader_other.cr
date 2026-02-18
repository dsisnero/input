require "cancel_reader"

module Input
  def self.new_cancelreader(r : IO, flags : Int32) : CancelReader::Reader
    # Non-Windows implementation delegates to cancel_reader shard
    CancelReader.new_reader(r)
  end
end
