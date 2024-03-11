require "rails_helper"

RSpec.describe TraineeDetailsStep, type: :model do
  subject(:step) { described_class.new(form) }

  let(:form) { build(:form) }

  hint = 'The course must:
  <ul class="govuk-hint govuk-list govuk-list--bullet">
  <li>pay a salary</li>
  <li>lead to qualified teacher status (QTS)</li>
  <li>be accredited by the UK government</li>
 </ul>
Check with your training provider if you\'re not sure.
'

  include_examples "behaves like a step",
                   described_class,
                   route_key: "trainee-details",
                   required_fields: %i[state_funded_secondary_school],
                   question: "Are you on a teacher training course in England which meets the following conditions?",
                   question_hint: hint,
                   question_type: :radio,
                   valid_answers: %w[Yes No]
end
