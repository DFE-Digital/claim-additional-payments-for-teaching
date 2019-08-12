module ExcelUtils
  FORMULA_TRIGGERS = %w[- + = @].freeze

  # Escapes potentially formula-triggering characters from the front of the
  # string, i.e. +,-,=,@
  def self.escape_formulas(string)
    if ExcelUtils::FORMULA_TRIGGERS.include?(string&.chr)
      "\\" + string
    else
      string
    end
  end
end
