require "rails_helper"
require "excel_utils"

RSpec.describe ExcelUtils do
  describe "escape_formulas" do
    it "escapes formula-triggering characters at the beginning of a string" do
      expect(ExcelUtils.escape_formulas("=1+2")).to eq '\=1+2'
      expect(ExcelUtils.escape_formulas("@reference")).to eq '\@reference'
      expect(ExcelUtils.escape_formulas("-12 + 13")).to eq '\-12 + 13'
      expect(ExcelUtils.escape_formulas("+12 + 13")).to eq '\+12 + 13'
    end

    it "doesn't escape non-formula-triggering characters" do
      expect(ExcelUtils.escape_formulas("1 Buckingham Palace")).to eq "1 Buckingham Palace"
    end

    it "doesn't escape characters in the body of a string" do
      expect(ExcelUtils.escape_formulas("some+address@email.com")).to eq "some+address@email.com"
      expect(ExcelUtils.escape_formulas('\a-url?')).to eq '\a-url?'
    end
  end
end
