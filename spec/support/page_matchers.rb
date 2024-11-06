module PageMatchers
  # Matcher for items within the [Summary list](https://design-system.service.gov.uk/components/summary-list/) component.
  class HaveSummaryItem
    attr_reader :exact_text

    def initialize(key:, value:, exact_text: true)
      @key = key
      @value = value
      @exact_text = exact_text
    end

    def matches?(page)
      page.find("dt", text: @key, exact_text:).sibling("dd", text: @value, exact_text:)
    end
  end

  def have_summary_item(key:, value:, exact_text: true)
    HaveSummaryItem.new(key:, value:, exact_text:)
  end

  def have_summary_error(text)
    have_css(".govuk-error-summary__list", text: text)
  end
end
