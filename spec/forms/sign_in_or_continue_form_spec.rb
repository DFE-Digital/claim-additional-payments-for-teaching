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
      claims = journey::POLICIES.map { |policy| create(:claim, policy: policy) }
      CurrentClaim.new(claims: claims)
    end

    let(:slug) { "sign-in-of-continue" }

    subject(:form) { described_class.new(claim: current_claim, journey: journey, params: params) }

    describe "initialize" do
      context "teacher id enabled" do
        it "does not call ClaimUserDetailsReset with :skipped_tid" do
          expect(DfeIdentity::ClaimUserDetailsReset).not_to receive(:call).with(current_claim, :skipped_tid)

          form
        end
      end

      context "teacher id disabled" do
        let(:teacher_id_enabled) { false }

        it "calls ClaimUserDetailsReset with :skipped_tid" do
          expect(DfeIdentity::ClaimUserDetailsReset).to receive(:call).with(current_claim, :skipped_tid)

          form
        end
      end
    end

    describe "force_update_session_with_current_slug" do
      context "teacher id enabled" do
        it "returns true" do
          expect(form.force_update_session_with_current_slug).to be true
        end
      end

      context "teacher id disabled" do
        let(:teacher_id_enabled) { false }

        it "returns true" do
          expect(form.force_update_session_with_current_slug).to be true
        end
      end
    end

    describe "redirect_to_next_slug" do
      context "teacher id enabled" do
        it "returns false" do
          expect(form.redirect_to_next_slug).to be false
        end
      end

      context "teacher id disabled" do
        let(:teacher_id_enabled) { false }

        it "returns true" do
          expect(form.redirect_to_next_slug).to be true
        end
      end
    end

    describe "save" do
      context "user selects to continue without teacher id explicitely" do
        it "calls ClaimUserDetailsReset with :skipped_tid" do
          expect(DfeIdentity::ClaimUserDetailsReset).to receive(:call).with(current_claim, :skipped_tid)

          form.save
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
