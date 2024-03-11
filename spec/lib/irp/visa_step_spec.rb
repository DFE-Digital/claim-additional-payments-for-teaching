require "rails_helper"

RSpec.describe VisaStep, type: :model do
  subject(:step) { described_class.new(form) }

  let(:form) { build(:form) }

  include_examples "behaves like a step",
                   described_class,
                   route_key: "visa",
                   required_fields: %i[visa_type],
                   question: "Select the visa you used to move to England",
                   question_type: :select,
                   valid_answers: VisaStep::VALID_ANSWERS_OPTIONS
end
