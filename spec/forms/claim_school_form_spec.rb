require "rails_helper"

RSpec.describe ClaimSchoolForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }

  before { create(:journey_configuration, :student_loans) }

  let(:current_claim) do
    claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
    CurrentClaim.new(claims: claims)
  end

  let(:slug) { "claim-school" }

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

    context "searching for a school" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}, school_search: "Some school name"}) }

      it "returns claim-school" do
        expect(form.backlink_path).to eq "claim-school"
      end
    end
  end

  describe "#schools" do
    context "new form" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

      it "returns nil" do
        expect(form.schools).to be_nil
      end
    end

    context "searching for a school" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}, school_search: "Some school name"}) }

      it "returns a list of schools" do
        schools = [create(:school), create(:school)]
        allow(School).to receive(:search).with("Some school name").and_return(schools)

        expect(form.schools).to eq schools
      end
    end
  end

  describe "#claim_school_name" do
    let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

    context "claim eligibility DOES NOT have a claim school" do
      it "returns nil" do
        expect(form.claim_school_name).to be_nil
      end
    end

    context "claim eligibility DOES have a claim school" do
      let(:school) { create(:school, :eligible_for_journey, journey: journey) }

      let(:current_claim) do
        claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, eligibility_attributes: {claim_school: school}) }
        CurrentClaim.new(claims: claims)
      end

      it "returns school name" do
        expect(form.claim_school_name).to eq school.name
      end
    end
  end

  describe "#save" do
    context "claim_school_id submitted" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {claim_school_id: school.id}}) }

      let(:school) { create(:school, :eligible_for_journey, journey: journey) }

      context "claim eligibility didn't have claim_school" do
        let(:current_claim) do
          claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
          CurrentClaim.new(claims: claims)
        end

        it "updates the claim_school on claim eligibility" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            eligibility = claim.eligibility.reload

            expect(eligibility.claim_school_id).to eq school.id
          end
        end
      end

      context "claim eligibility already had a claim_school" do
        let(:previous_school) { create(:school, :eligible_for_journey, journey: journey) }

        let(:current_claim) do
          claims = journey::POLICIES.map { |policy| create(:claim, policy: policy, eligibility_attributes: {claim_school_id: previous_school.id}) }
          CurrentClaim.new(claims: claims)
        end

        it "updates the claim_school on claim eligibility" do
          expect(form.save).to be true

          current_claim.claims.each do |claim|
            eligibility = claim.eligibility.reload

            expect(eligibility.claim_school_id).to eq school.id
          end
        end
      end

      context "submitted claim_school_id doesn't exist - form manipulated" do
        let(:school) { double(id: "99999999999") }

        it "does not save and adds error to form" do
          expect(form.save).to be false
          expect(form.errors[:claim_school_id]).to eq ["School not found"]
        end
      end

      context "claim model fails validation unexpectedly" do
        it "raises an error" do
          allow(current_claim).to receive(:save!).and_raise(ActiveRecord::RecordInvalid)

          expect { form.save }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context "claim_school_id missing" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {claim_school_id: ""}}) }

      it "does not save and adds error to form" do
        expect(form.save).to be false
        expect(form.errors[:claim_school_id]).to eq ["Select a school from the list or search again for a different school"]
      end
    end
  end

  describe "no_search_results?" do
    context "no schools found" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}, school_search: "Some school name"}) }

      it "returns true" do
        allow(School).to receive(:search).with("Some school name").and_return([])

        expect(form.no_search_results?).to be true
      end
    end

    context "school_search less than 3 characters" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {}, school_search: "Ab"}) }

      it "returns false" do
        expect(form.no_search_results?).to be false
      end
    end
  end
end
