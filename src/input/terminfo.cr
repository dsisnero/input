require "terminfo"

module Input
  class TerminfoCompat
    def initialize(@data : ::Terminfo::Data)
    end

    def string_caps_short : Hash(String, String)
      caps = Hash(String, String).new
      @data.strings.each do |name, seq|
        alias_info = ::Terminfo::Alias::Strings[name]?
        next if alias_info.nil?
        short_name = alias_info[0]?
        next if short_name.nil? || short_name.empty?
        caps[short_name] = seq
      end
      caps
    end

    def ext_string_caps_short : Hash(String, String)
      caps = Hash(String, String).new
      return caps unless @data.extended_header
      @data.extended_strings.each do |name, seq|
        caps[name] = seq
      end
      caps
    end
  end

  private def self.load_terminfo(term : String) : TerminfoCompat?
    TerminfoCompat.new(::Terminfo::Data.new(term: term))
  rescue
    nil
  end
end
