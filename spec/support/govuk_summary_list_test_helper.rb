module GovukSummaryListTestHelper
  def summary_row(label)
    find("dt", text: label).sibling(:css, "dd:first")
  end

  def summary_card(heading)
    match = all(".govuk-summary-card").detect do |card|
      card.find(".govuk-summary-card__title").text == heading
    end

    raise "Couldn't find summary card with title #{heading}" unless match

    match
  end
end
