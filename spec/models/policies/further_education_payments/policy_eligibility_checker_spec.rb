require "rails_helper"

describe Policies::FurtherEducationPayments::PolicyEligibilityChecker do
  let(:answers) do
    build(:further_education_payments_answers)
  end

  subject { described_class.new(answers: answers) }

  describe "#status, #ineligible?, #ineligibility_reason" do
    context "when ineligible as lacking teaching responsibility" do
      let(:answers) do
        build(:further_education_payments_answers, teaching_responsibilities: false)
      end

      it "is ineligble as :lack_teaching_responsibilities" do
        expect(subject).to be_ineligible
        expect(subject.status).to eql(:ineligible)
        expect(subject.ineligibility_reason).to eql(:lack_teaching_responsibilities)
      end
    end
  end
end
