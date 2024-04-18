require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::IttYearForm do
  shared_examples "itt_academic_year_form" do |journey|
    before {
      create(:journey_configuration, :additional_payments)
    }

    let(:current_claim) do
      claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, eligibility_attributes: {qualification: "postgraduate_itt"}) }
      CurrentClaim.new(claims: claims)
    end

    let(:slug) { "itt_year" }

    subject(:form) { described_class.new(claim: current_claim, journey: journey, params: params) }

    context "unpermitted claim param" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {nonsense_id: 1}}) }

      it "raises an error" do
        expect { form }.to raise_error ActionController::UnpermittedParameters
      end
    end

    describe "#backlink_path" do
      context "new form" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

        it "returns nil" do
          expect(form.backlink_path).to be_nil
        end
      end
    end

    describe "#itt_academic_year" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

      context "claim eligibility DOES NOT have a current value" do
        it "returns nil" do
          expect(form.itt_academic_year).to be_nil
        end
      end

      context "claim eligibility DOES have a current value" do
        let(:current_value) { AcademicYear.new(4.years.ago.year) }

        let(:current_claim) do
          claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, eligibility_attributes: {itt_academic_year: current_value}) }
          CurrentClaim.new(claims: claims)
        end

        it "returns the current value" do
          expect(form.itt_academic_year).to eq current_value
        end
      end
    end

    describe "#save" do
      context "itt_academic_year submitted" do
        let(:new_value) { AcademicYear.new(2.years.ago.year).to_s }

        let(:params) { ActionController::Parameters.new({slug: slug, claim: {itt_academic_year: new_value}}) }

        context "claim eligibility didn't have itt_academic_year" do
          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
            CurrentClaim.new(claims: claims)
          end

          it "updates the itt_academic_year on claim eligibility" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              eligibility = claim.eligibility.reload

              expect(eligibility.itt_academic_year).to eq new_value
            end
          end
        end

        context "claim eligibility already had a itt_academic_year" do
          let(:new_value) { AcademicYear.new(2.years.ago.year).to_s }

          let(:current_claim) do
            claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, eligibility_attributes: {itt_academic_year: AcademicYear.new(4.years.ago.year)}) }
            CurrentClaim.new(claims: claims)
          end

          it "updates the itt_academic_year on claim eligibility" do
            expect(form.save).to be true

            current_claim.claims.each do |claim|
              eligibility = claim.eligibility.reload

              expect(eligibility.itt_academic_year).to eq new_value
            end
          end
        end

        context "claim model fails validation unexpectedly" do
          it "raises an error" do
            allow(current_claim).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

            expect { form.save }.to raise_error(ActiveRecord::RecordInvalid)
          end
        end
      end

      context "itt_academic_year missing" do
        let(:params) { ActionController::Parameters.new({slug: slug, claim: {itt_academic_year: ""}}) }

        it "does not save and adds error to form" do
          expect(form.save).to be false
          expect(form.errors[:itt_academic_year]).to eq ["Select the academic year you started your postgraduate ITT"]
        end
      end
    end

    describe "#qualification_is?" do
      let(:params) { ActionController::Parameters.new({slug: slug}) }

      it "returns true for a single argument match" do
        expect(form.qualification_is?(:postgraduate_itt)).to be true
      end

      it "returns false for a single argument miss" do
        expect(form.qualification_is?(:undergraduate_itt)).to be false
      end

      it "returns true for an argument match" do
        expect(form.qualification_is?(:undergraduate_itt, :postgraduate_itt, :other)).to be true
      end

      it "returns false for an argument miss" do
        expect(form.qualification_is?(:undergraduate_itt, :assessment_only, :other)).to be false
      end
    end
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "itt_academic_year_form", Journeys::AdditionalPaymentsForTeaching
  end
end
