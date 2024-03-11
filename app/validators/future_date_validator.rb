class FutureDateValidator
  def initialize(record, field)
    @record = record
    @field = field
    @test_date = record.public_send(field)
  end

  def validate
    return unless test_date.present? && test_date > Date.current

    record.errors.add(field, :not_in_future)
  end

private

  attr_reader :record, :field, :test_date
end
