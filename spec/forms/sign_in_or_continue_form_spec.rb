require "rails_helper"

RSpec.describe SignInOrContinueForm do
  shared_examples "sign_in_or_continue_form" do |journey|
    let(:teacher_id_enabled) { true }
    let(:params) { ActionController::Parameters.new({slug: slug, claim: {}}) }

    before {
      create(:journey_configuration, :student_loans, teacher_id_enabled: teacher_id_enabled)
      create(:journey_configuration, :additional_payments, teacher_id_enabled: teacher_id_enabled)
    }

    let(:current_claim) do
      claims = journey::POLICIES.map do |policy|
        create(:claim, :with_details_from_dfe_identity, policy: policy)
      end
      CurrentClaim.new(claims: claims)
    end

    let(:slug) { "sign-in-of-continue" }

    subject(:form) { described_class.new(claim: current_claim, journey: journey, params: params) }

    describe "save" do
      before { form.save }
      context "user selects to continue without teacher id explicitely" do
        it "resets any details from teacher id" do
          current_claim.claims.each do |claim|
            expect(claim.first_name).to eq("")
            expect(claim.surname).to eq("")
            expect(claim.teacher_reference_number).to eq("")
            expect(claim.date_of_birth).to be_nil
            expect(claim.national_insurance_number).to eq("")
            expect(claim.logged_in_with_tid).to be false
            expect(claim.details_check).to be_nil
            expect(claim.teacher_id_user_info).to eq({})
          end
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples "sign_in_or_continue_form", Journeys::TeacherStudentLoanReimbursement
  end

  describe "for AdditionalPaymentsForTeaching journey" do
    include_examples "sign_in_or_continue_form", Journeys::AdditionalPaymentsForTeaching
  end
end
