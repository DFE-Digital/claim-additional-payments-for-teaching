module GovukSummaryListTestHelper
  def summary_row(label)
    find("div.govuk-summary-list__row", text: label)
  end
end
