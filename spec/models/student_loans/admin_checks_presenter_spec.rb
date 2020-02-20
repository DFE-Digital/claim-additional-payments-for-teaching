require "rails_helper"

RSpec.describe StudentLoans::AdminChecksPresenter, type: :model do
  let(:school) { schools(:penistone_grammar_school) }
  let(:eligibility) do
    build(
      :student_loans_eligibility,
      qts_award_year: "on_or_after_cut_off_date",
      claim_school: school,
      current_school: school,
    )
  end
  subject(:presenter) { described_class.new(eligibility) }

  describe "#qualifications" do
    it "returns an array of label and values for displaying information for qualification checks" do
      expect(presenter.qualifications).to eq [["Award year", "In or after the academic year 2013 to 2014"]]
    end
  end

  describe "#employment" do
    it "returns an array of label and values for displaying information for employment checks" do
      expect(presenter.employment).to eq [
        ["6 April 2018 to 5 April 2019", presenter.display_school(eligibility.claim_school)],
        [I18n.t("admin.current_school"), presenter.display_school(eligibility.current_school)],
      ]
    end
  end
end
