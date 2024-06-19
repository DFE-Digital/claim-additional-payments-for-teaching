require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::AnswersPresenter do
  let(:journey_session) do
    create(:get_a_teacher_relocation_payment_session, answers: answers)
  end

  let(:presenter) { described_class.new(journey_session) }

  describe "#eligibility_answers" do
    subject { presenter.eligibility_answers }

    let(:answers) do
      build(
        :get_a_teacher_relocation_payment_answers,
        :with_application_route
      )
    end

    it do
      is_expected.to include(
        [
          "What is your employment status?",
          "I am employed as a teacher in a school in England",
          "application-route"
        ]
      )
    end
  end
end
