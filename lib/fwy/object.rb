module Fwy
  class Object < OpenStruct
    def initialize(attributes)
      super to_ostruct(attributes)
    end

    def to_ostruct(obj)
      if obj.is_a?(Hash)
        OpenStruct.new(obj.map { |k, v| [k, to_ostruct(v)] }.to_h)
      elsif obj.is_a?(Array)
        obj.map { |o| to_ostruct(o) }
      elsif obj.is_a?(String)
        string_reader(obj)&.strip
      else # Likely a primative value
        obj
      end
    end

    def date_reader(value)
      return if nil_value?(value)

      begin
        Date.parse(value)
      rescue Date::Error, TypeError
        begin
          Time.at(Integer(value), in: "UTC").to_date
        rescue ArgumentError => e
          Rollbar.error(e)

          nil
        end
      end
    end

    def boolean_reader(value)
      return if nil_value?(value)

      value.to_s.strip.downcase == "true"
    end

    def integer_reader(value)
      return if nil_value?(value)

      begin
        Integer(value)
      rescue ArgumentError => e
        Rollbar.error(e)

        nil
      end
    end

    def string_reader(value)
      return if nil_value?(value)

      value = value.to_s
      value = yield value if block_given?

      value
    end

    def nil_value?(value)
      value.nil? ||
        ["nil", "null"].any?(
          value
            .to_s
            .strip
            .downcase
        )
    end
  end
end
