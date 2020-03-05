require "rails_helper"

describe StudentLoansHelper do
  describe "#claim_school_question" do
    it "returns the question for claim school question in the Student Loans journey, based on the configured current academic year" do
      expect(policy_configurations(:student_loans).current_academic_year).to eq AcademicYear.new("2025/2026")
      expect(helper.claim_school_question).to eq "Which school were you employed to teach at between 6 April 2024 and 5 April 2025?"

      policy_configurations(:student_loans).update!(current_academic_year: "2019/2020")
      expect(helper.claim_school_question).to eq "Which school were you employed to teach at between 6 April 2018 and 5 April 2019?"
    end

    it "rewords the question if looking for an additional school" do
      expect(helper.claim_school_question(additional_school: true)).to eq "Which additional school were you employed to teach at between 6 April 2024 and 5 April 2025?"
    end
  end

  describe "#subjects_taught_question" do
    it "returns the question for the subjects taught question in the Student Loans journey mentioning the school, based on the configured current academic year" do
      expect(policy_configurations(:student_loans).current_academic_year).to eq AcademicYear.new("2025/2026")
      expect(helper.subjects_taught_question(school_name: "Edward Tilghman Middle")).to eq "Which of the following subjects did you teach at Edward Tilghman Middle between 6 April 2024 and 5 April 2025?"
    end
  end

  describe "#leadership_position_question" do
    it "returns the question for the leadership position question in the Student Loans journey, based on the configured current academic year" do
      expect(policy_configurations(:student_loans).current_academic_year).to eq AcademicYear.new("2025/2026")
      expect(helper.leadership_position_question).to eq "Were you employed in a leadership position between 6 April 2024 and 5 April 2025?"
    end
  end

  describe "#mostly_performed_leadership_duties_question" do
    it "returns the question for the mostly performed leadership duties question in the Student Loans journey, based on the configured current academic year" do
      expect(policy_configurations(:student_loans).current_academic_year).to eq AcademicYear.new("2025/2026")
      expect(helper.leadership_position_question).to eq "Were you employed in a leadership position between 6 April 2024 and 5 April 2025?"
    end
  end

  describe "#student_loan_amount_question" do
    it "returns the question for the student laon amount question in the Student Loans journey" do
      expect(helper.student_loan_amount_question).to eq "Exactly how much student loan did you repay while employed as a teacher between 6 April 2018 and 5 April 2019?"
    end
  end
end
