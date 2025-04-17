require "rails_helper"

RSpec.describe StudentLoansHelper do
  let!(:journey_configuration) { create(:journey_configuration, :student_loans) }
  let(:current_academic_year) { AcademicYear.current }

  describe "#claim_school_question" do
    it "returns the question for claim school question in the Student Loans journey, based on the configured current academic year" do
      expect(helper.claim_school_question).to eq "Which school were you employed to teach at between 6 April #{current_academic_year.start_year - 1} and 5 April #{current_academic_year.end_year - 1}?"

      journey_configuration.update!(current_academic_year: "2019/2020")
      expect(helper.claim_school_question).to eq "Which school were you employed to teach at between 6 April 2018 and 5 April 2019?"
    end

    it "rewords the question if looking for an additional school" do
      expect(helper.claim_school_question(additional_school: true)).to eq "Which additional school were you employed to teach at between 6 April #{current_academic_year.start_year - 1} and 5 April #{current_academic_year.end_year - 1}?"
    end
  end

  describe "#subjects_taught_question" do
    it "returns the question for the subjects taught question in the Student Loans journey mentioning the school, based on the configured current academic year" do
      expect(helper.subjects_taught_question(school_name: "Edward Tilghman Middle")).to eq "Which of the following subjects did you teach at Edward Tilghman Middle between 6 April #{current_academic_year.start_year - 1} and 5 April #{current_academic_year.end_year - 1}?"
    end
  end

  describe "#leadership_position_question" do
    it "returns the question for the leadership position question in the Student Loans journey, based on the configured current academic year" do
      expect(helper.leadership_position_question).to eq "Were you employed in a leadership position between 6 April #{current_academic_year.start_year - 1} and 5 April #{current_academic_year.end_year - 1}?"
    end
  end

  describe "#mostly_performed_leadership_duties_question" do
    it "returns the question for the mostly performed leadership duties question in the Student Loans journey, based on the configured current academic year" do
      expect(helper.leadership_position_question).to eq "Were you employed in a leadership position between 6 April #{current_academic_year.start_year - 1} and 5 April #{current_academic_year.end_year - 1}?"
    end
  end
end
