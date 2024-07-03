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
        :with_teacher_application_route,
        :with_state_funded_secondary_school,
        :with_one_year_contract,
        :with_start_date,
        :with_subject,
        :with_visa,
        :with_entry_date,
        :with_nationality
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
        ],
        [
          "Enter the date you moved to England to start your teaching job",
          answers.date_of_entry.strftime("%d-%m-%Y"),
          "entry-date"
        ]
      )
    end
  end

  describe "#identity_answers" do
    subject { presenter.identity_answers }

    let(:answers) do
      build(
        :get_a_teacher_relocation_payment_answers,
        :with_nationality,
        :with_passport_number
      )
    end

    it do
      is_expected.to include(
        [
          "Select your nationality",
          "Australian",
          "nationality"
        ],
        [
          "Enter your passport number, as it appears on your passport",
          "1234567890123456789A",
          "passport-number"
        ]
      )
    end
  end

  describe "#employment_answers" do
    subject { presenter.employment_answers }

    let(:answers) do
      build(
        :get_a_teacher_relocation_payment_answers,
        :with_employment_details
      )
    end

    it do
      is_expected.to include(
        [
          "Which school are you currently employed to teach at?",
          answers.current_school.name,
          "current-school"
        ],
        [
          "Enter the name of the headteacher of the school where you are employed as a teacher",
          "Seymour Skinner",
          "headteacher-details"
        ]
      )
    end
  end
end
