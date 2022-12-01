module PageMatchers
  # Matcher for items within the [Summary list](https://design-system.service.gov.uk/components/summary-list/) component.
  class HaveSummaryItem
    def initialize(key:, value:)
      @key = key
      @value = value
    end

    def matches?(page)
      page.find("dt", text: @key, exact_text: true).sibling("dd", text: @value, exact_text: true)
    end
  end

  def have_summary_item(key:, value:)
    HaveSummaryItem.new(key: key, value: value)
  end

  def have_summary_error(text)
    have_css(".govuk-error-summary__list", text: text)
  end
end
