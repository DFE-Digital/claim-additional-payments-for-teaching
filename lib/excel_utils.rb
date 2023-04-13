module ExcelUtils
  FORMULA_TRIGGERS = %w[- + = @].freeze

  # Escapes potentially formula-triggering characters from the front of the
  # string, i.e. +,-,=,@
  def self.escape_formulas(value)
    if value.is_a?(String) && ExcelUtils::FORMULA_TRIGGERS.include?(value&.chr)
      "\\" + value
    else
      value
    end
  end
end
