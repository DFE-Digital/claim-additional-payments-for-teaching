module ApplicationHelper
  def page_title(title)
    content_for :page_title do
      "#{title} – #{t("student_loans.journey_name")} – GOV.UK"
    end
  end

  def claim_in_progress?
    session.key?(:claim_id)
  end

  def currency_value_for_number_field(value)
    return if value.nil?

    number_to_currency(value, delimiter: "", unit: "")
  end
end
