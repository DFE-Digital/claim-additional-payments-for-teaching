module FurtherEducationPayments
  class TeachingHours
    VALUES = [
      "more_than_20",
      "more_than_12",
      "between_2_5_and_12",
      "less_than_2_5"
    ]

    VALUES.each do |supported_value|
      define_singleton_method(supported_value) do
        supported_value
      end

      define_method "#{supported_value}?" do
        @value == supported_value
      end
    end

    def initialize(value)
      if value.is_a?(self.class)
        value = value.instance_variable_get(:@value)
      end

      raise ArgumentError unless value.in?(VALUES)

      @value = value
    end

    def __value
      @value
    end

    def ==(other)
      unless other.is_a?(self.class)
        raise ArgumentError, "`#{other}` is not a `#{self.class}`"
      end

      other.__value == @value
    end

    def upperband?
      more_than_20? || more_than_12?
    end

    def to_s
      @value
    end
  end
end
