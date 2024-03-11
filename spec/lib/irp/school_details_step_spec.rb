require "rails_helper"

RSpec.describe SchoolDetailsStep, type: :model do
  subject(:step) { described_class.new(form) }

  let(:form) { build(:form) }

  include_examples "behaves like a step",
                   described_class,
                   route_key: "school-details",
                   required_fields: %i[state_funded_secondary_school],
                   question: "Are you employed by an English state secondary school?",
                   question_hint: "State schools receive funding from the UK government. Secondary schools teach children aged 11 to 16, or 11 to 18.",
                   question_type: :radio,
                   valid_answers: %w[Yes No]
end
