require "ansi"

module Input
  # PrimaryDeviceAttributesEvent is an event that represents the terminal
  # primary device attributes.
  class PrimaryDeviceAttributesEvent < Event
    getter params : Array(Int32)

    def initialize(@params : Array(Int32))
    end

    def ==(other : self) : Bool
      @params == other.params
    end

    def_hash @params
  end

  private def self.parse_primary_dev_attrs(params : Ansi::Params) : Event
    # Primary Device Attributes
    da1 = Array(Int32).new(params.size)
    params.each do |param|
      unless param.has_more?
        da1 << param.param(0)
      end
    end
    PrimaryDeviceAttributesEvent.new(da1)
  end
end
