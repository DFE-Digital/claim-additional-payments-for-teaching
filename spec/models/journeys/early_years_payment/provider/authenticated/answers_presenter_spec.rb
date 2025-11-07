require "rails_helper"

RSpec.describe Journeys::EarlyYearsPayment::Provider::Authenticated::AnswersPresenter do
  let(:journey_session) do
    create(:early_years_payment_provider_authenticated_session, answers: answers)
  end

  let(:presenter) { described_class.new(journey_session) }

  describe "#claim_answers" do
    subject { presenter.claim_answers }

    let(:answers) { build(:early_years_payment_provider_authenticated_answers, :eligible) }

    it do
      is_expected.to include(
        [
          "Employee’s workplace",
          Policies::EarlyYearsPayments::EligibleEyProvider.first.nursery_name,
          "current-nursery"
        ],
        [
          "Employer’s PAYE reference number",
          "123/A",
          "paye-reference"
        ],
        [
          "Employee’s name",
          "John Doe",
          "claimant-name"
        ],
        [
          "Employee’s start date",
          (Policies::EarlyYearsPayments::ELIGIBLE_START_DATE + 1.day).strftime("%d %B %Y"),
          "start-date"
        ],
        [
          "Employee’s contract type",
          "Permanent",
          "contract-type"
        ],
        [
          "Confirmation that employee spends most of their time in their job working directly with children",
          "Yes",
          "child-facing"
        ],
        [
          "Confirmation that employee worked in an early years setting 6 months before the start date",
          "Yes",
          "returner"
        ],
        [
          "Employee’s email address",
          "johndoe@example.com",
          "employee-email"
        ]
      )
    end
  end
end
