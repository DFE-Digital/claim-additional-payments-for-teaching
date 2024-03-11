require "rails_helper"

RSpec.describe ApplicationRouteStep, type: :model do
  subject(:step) { described_class.new(form) }

  let(:form) { build(:form) }

  include_examples "behaves like a step",
                   described_class,
                   route_key: "application-route",
                   required_fields: %i[application_route],
                   question: "What is your employment status?",
                   question_hint: "Select one of the following options.",
                   question_type: :radio,
                   valid_answers: [
                     "I am employed as a teacher in a school in England",
                     "I am enrolled on a salaried teacher training course in England",
                     "Other",
                   ]
end
