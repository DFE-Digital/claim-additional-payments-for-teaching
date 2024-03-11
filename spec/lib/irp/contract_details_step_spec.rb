require "rails_helper"

RSpec.describe ContractDetailsStep, type: :model do
  subject(:step) { described_class.new(form) }

  let(:form) { build(:form) }

  include_examples "behaves like a step",
                   described_class,
                   route_key: "contract-details",
                   required_fields: %i[one_year],
                   question: "Are you employed on a contract lasting at least one year?",
                   question_hint: "Your contract can also be ongoing or permanent.",
                   question_type: :radio,
                   valid_answers: %w[Yes No]
end
