class EntryDateStep < BaseStep
  ROUTE_KEY = "entry-date".freeze

  REQUIRED_FIELDS = %i[date_of_entry].freeze

  validate do |record|
    FutureDateValidator.new(record, :date_of_entry).validate
  end

  def configure_step
    @question = t("steps.entry_date.question.#{form.application_route}")
    @question_type = :date
  end
end
