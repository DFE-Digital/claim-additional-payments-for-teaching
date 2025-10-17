require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::AdminTasksPresenter do
  subject do
    described_class.new(claim)
  end

  let(:claim) do
    build(
      :claim,
      :further_education,
      eligibility:
    )
  end

  describe "#provider_verification_rows" do
    context "continued_employment" do
      context "when provider answers claimant is" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            :provider_verification_completed
          )
        end

        it "returns Yes" do
          expect(subject.provider_verification_rows[9][0]).to eql("Continued employment")
          expect(subject.provider_verification_rows[9][1]).to eql("N/A")
          expect(subject.provider_verification_rows[9][2]).to eql("Yes")
        end
      end

      context "when provider answers claimant is not" do
        let(:eligibility) do
          build(
            :further_education_payments_eligibility,
            :provider_verification_completed,
            provider_verification_continued_employment: false
          )
        end

        it "returns No" do
          expect(subject.provider_verification_rows[9][0]).to eql("Continued employment")
          expect(subject.provider_verification_rows[9][1]).to eql("N/A")
          expect(subject.provider_verification_rows[9][2]).to eql("No")
        end
      end
    end
  end
end
