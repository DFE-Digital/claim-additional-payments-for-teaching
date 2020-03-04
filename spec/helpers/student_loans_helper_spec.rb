require "rails_helper"

describe StudentLoansHelper do
  describe "#claim_school_question" do
    it "returns the question for claim school question in the Student Loans journey" do
      expect(helper.claim_school_question(false)).to eq "Which school were you employed to teach at between 6 April 2018 and 5 April 2019?"
    end

    it "rewords the question if looking for an additional school" do
      expect(helper.claim_school_question(true)).to eq "Which additional school were you employed to teach at between 6 April 2018 and 5 April 2019?"
    end
  end
end
