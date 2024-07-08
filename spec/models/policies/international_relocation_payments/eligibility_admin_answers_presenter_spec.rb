require "rails_helper"

RSpec.describe Policies::InternationalRelocationPayments::EligibilityAdminAnswersPresenter, type: :model do
  describe "#answers" do
    subject { described_class.new(eligibility).answers }

    let(:school) { create(:school) }

    let(:eligibility) do
      build(
        :international_relocation_payments_eligibility,
        nationality: "American",
        passport_number: "123456789",
        current_school: school,
        subject: "physics",
        school_headteacher_name: "Principal Skinner",
        start_date: Date.new(2024, 3, 1),
        visa_type: "British National (Overseas) visa",
        date_of_entry: Date.new(2024, 2, 1)
      )
    end

    it do
      is_expected.to include(
        [
          "Nationality",
          "American"
        ],
        [
          "Passport number",
          "123456789"
        ],
        [
          "Current school",
          /#{school.name}/
        ],
        [
          "Subject",
          "Physics"
        ],
        [
          "School headteacher name",
          "Principal Skinner"
        ],
        [
          "Contract start date",
          "1 March 2024"
        ],
        [
          "Visa type",
          "British National (Overseas) visa"
        ],
        [
          "Date of entry",
          "1 February 2024"
        ]
      )
    end
  end
end
