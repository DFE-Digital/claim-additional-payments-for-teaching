require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::AnswersPresenter do
  let(:journey_session) do
    create(:get_a_teacher_relocation_payment_session, answers: answers)
  end

  let(:presenter) { described_class.new(journey_session) }

  describe "#eligibility_answers" do
    subject { presenter.eligibility_answers }

    context "when a teacher application" do
      let(:answers) do
        build(
          :get_a_teacher_relocation_payment_answers,
          :with_teacher_application_route,
          :with_state_funded_secondary_school,
          :with_one_year_contract,
          :with_start_date,
          :with_subject,
          :with_visa
        )
      end

      it do
        is_expected.to include(
          [
            "What is your employment status?",
            "I am employed as a teacher in a school in England",
            "application-route"
          ],
          [
            "Are you employed by an English state secondary school?",
            "Yes",
            "state-funded-secondary-school"
          ],
          [
            "Are you employed on a contract lasting at least one year?",
            "Yes",
            "contract-details"
          ],
          [
            "Enter the start date of your contract",
            answers.start_date.strftime("%d-%m-%Y"),
            "start-date"
          ],
          [
            "What subject are you employed to teach at your school?",
            "Physics",
            "subject"
          ],
          [
            "Select the visa you used to move to England",
            "British National (Overseas) visa",
            "visa"
          ]
        )
      end
    end

    context "when a trainee application" do
      let(:answers) do
        build(
          :get_a_teacher_relocation_payment_answers,
          :with_trainee_application_route,
          :with_state_funded_secondary_school,
          :with_start_date,
          :with_subject
        )
      end

      it do
        is_expected.to include(
          [
            "What is your employment status?",
            "I am enrolled on a salaried teacher training course in England",
            "application-route"
          ],
          [
            "Are you on a teacher training course in England which meets the following conditions?",
            "Yes",
            "trainee-details"
          ],
          [
            "Enter the start date of your contract",
            answers.start_date.strftime("%d-%m-%Y"),
            "start-date"
          ],
          [
            "What subject are you training to teach?",
            "Physics",
            "subject"
          ]
        )
      end
    end
  end
end
