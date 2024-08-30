require "rails_helper"

describe Policies::EarlyYearsPayments::PolicyEligibilityChecker do
  subject { described_class.new(answers: answers) }

  describe "#status, #ineligible?, #ineligibility_reason" do
    context "not a returner" do
      let(:answers) do
        build(
          :early_years_payment_answers,
          returning_within_6_months: false,
          returner_worked_with_children: nil,
          returner_contract_type: nil
        )
      end

      it "is eligible" do
        expect(subject).to_not be_ineligible
        expect(subject.status).to eql(:eligible_now)
      end
    end

    context "returner, worked with children in non-permanent position" do
      let(:answers) do
        build(
          :early_years_payment_answers,
          returning_within_6_months: true,
          returner_worked_with_children: false,
          returner_contract_type: "voluntary_or_unpaid"
        )
      end

      it "is eligible" do
        expect(subject).to_not be_ineligible
        expect(subject.status).to eql(:eligible_now)
      end
    end

    # If user jumps between questions out-of-order, this situation could arise
    context "returner, did not work with children in permanent position" do
      let(:answers) do
        build(
          :early_years_payment_answers,
          returning_within_6_months: true,
          returner_worked_with_children: false,
          returner_contract_type: "permanent"
        )
      end

      it "is eligible" do
        expect(subject).to_not be_ineligible
        expect(subject.status).to eql(:eligible_now)
      end
    end

    context "returner, worked with children in permanent position" do
      let(:answers) do
        build(
          :early_years_payment_answers,
          returning_within_6_months: true,
          returner_worked_with_children: true,
          returner_contract_type: "permanent"
        )
      end

      it "is ineligible as :returner" do
        expect(subject).to be_ineligible
        expect(subject.status).to eql(:ineligible)
        expect(subject.ineligibility_reason).to eql(:returner)
      end
    end

    context "when ineligible as :nursery_is_not_listed" do
      let(:answers) do
        build(
          :early_years_payment_answers,
          nursery_urn: "none_of_the_above"
        )
      end

      it "is ineligble as :nursery_is_not_listed" do
        expect(subject).to be_ineligible
        expect(subject.status).to eql(:ineligible)
        expect(subject.ineligibility_reason).to eql(:nursery_is_not_listed)
      end
    end
  end
end
