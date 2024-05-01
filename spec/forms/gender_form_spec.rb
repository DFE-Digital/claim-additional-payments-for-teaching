require "rails_helper"

RSpec.describe GenderForm do
  shared_examples "gender_form" do |journey|
    before {
      create(:journey_configuration, :additional_payments)
    }

    let(:current_claim) do
      claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
      CurrentClaim.new(claims: claims)
    end

    let(:slug) { "gender" }

    subject(:form) { described_class.new(claim: current_claim, journey: journey, params: params) }

    context "unpermitted claim param" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {nonsense_id: 1}}) }

      it "raises an error" do
        expect { form }.to raise_error ActionController::UnpermittedParameters
      end
    end

    describe "#payroll_gender" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

      context "claim payroll_gender DOES NOT have a current value" do
        it "returns nil" do
          expect(form.payroll_gender).to be_nil
        end
      end

      context "claim payroll_gender DOES have a current value" do
        let(:current_claim) do
          claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, payroll_gender: Claim.payroll_genders[:male]) }
          CurrentClaim.new(claims: claims)
        end

        it "returns the current value" do
          expect(form.payroll_gender).to eq "male"
        end
      end
    end

    describe "#save" do
      context "payroll_gender submitted" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {payroll_gender: "female"}}) }

        context "claim didn't have payroll_gender" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
            CurrentClaim.new(claims: claims)
          end

          it "updates the payroll_gender on claim" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              expect(claim.reload.payroll_gender).to eq "female"
            end
          end
        end

        context "claim already had a payroll_gender" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, payroll_gender: Claim.payroll_genders[:dont_know]) }
            CurrentClaim.new(claims: claims)
          end

          it "updates the payroll_gender on claim" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              expect(claim.reload.payroll_gender).to eq "female"
            end
          end
        end

        context "claim model fails validation unexpectedly" do
          it "raises an error" do
            allow(current_claim).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)

            expect { form.save }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end

      context "payroll_gender missing" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {payroll_gender: ""}}) }

        it "does not save and adds error to form" do
          expect(form.save).to be false
          expect(form.errors[:payroll_gender]).to eq ["Select the gender recorded on your school’s payroll system or select whether you do not know"]
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "gender_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "gender_form", Journeys::AdditionalPaymentsForTeaching
  end
end
