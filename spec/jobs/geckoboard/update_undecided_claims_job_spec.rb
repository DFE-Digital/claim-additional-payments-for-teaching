require "rails_helper"

RSpec.describe Geckoboard::UpdateUndecidedClaimsJob do
  describe "#perform" do
    before do
      @dataset_post_stub = stub_geckoboard_dataset_update
    end

    it "updates the Geckoboard claim dataset with all undecided claims for the current academic year" do
      academic_year_2019 = AcademicYear.new("2019")
      academic_year_2020 = AcademicYear.new("2020")
      policy_configurations(:student_loans).update!(current_academic_year: "2020/2021")
      create_list(:claim, 2, :submitted, policy: StudentLoans, academic_year: academic_year_2019)
      claims_awaiting_decision_2020 = create_list(:claim, 2, :submitted, policy: StudentLoans, academic_year: academic_year_2020)
      create(:claim, :approved)
      create(:claim, :submittable)

      Geckoboard::UpdateUndecidedClaimsJob.new.perform

      expect(@dataset_post_stub.with { |request|
        request_body_matches_geckoboard_data_for_claims?(request, claims_awaiting_decision_2020)
      }).to have_been_requested
    end
  end
end
