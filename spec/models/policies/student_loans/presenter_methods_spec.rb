require "rails_helper"

RSpec.describe Policies::StudentLoans::PresenterMethods, type: :helper do
  describe ".qts_award_year_answer" do
    [
      {
        academic_year: "2023/2024",
        qts_award_year_answer_ineligible: "A different academic year",
        qts_award_year_answer_eligible: "Between the start of the 2013 to 2014 academic year and the end of the 2020 to 2021 academic year"
      },
      {
        academic_year: "2025/2026",
        qts_award_year_answer_ineligible: "A different academic year",
        qts_award_year_answer_eligible: "Between the start of the 2013 to 2014 academic year and the end of the 2020 to 2021 academic year"
      },
      {
        academic_year: "2031/2032",
        qts_award_year_answer_ineligible: "A different academic year",
        qts_award_year_answer_eligible: "Between the start of the 2019 to 2020 academic year and the end of the 2020 to 2021 academic year"
      }
    ].each do |args|
      it "returns a String representing the answer of the QTS question based on qts_award_year and the academic year (#{args[:academic_year]}) the claim was made in" do
        claim = build(:claim, academic_year: args[:academic_year])
        eligibility = build(:student_loans_eligibility, claim: claim)

        eligibility.qts_award_year = :before_cut_off_date
        expect(
          helper.qts_award_year_answer(
            eligibility.ineligible_qts_award_year?,
            eligibility.claim.academic_year
          )
        ).to eq args[:qts_award_year_answer_ineligible]

        eligibility.qts_award_year = :on_or_after_cut_off_date
        expect(
          helper.qts_award_year_answer(
            eligibility.ineligible_qts_award_year?,
            eligibility.claim.academic_year
          )
        ).to eq args[:qts_award_year_answer_eligible]
      end
    end
  end
end
