require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::CheckYourAnswersForm do
  before do
    create(:journey_configuration, :further_education_payments, current_academic_year:)
  end

  let(:current_academic_year) { AcademicYear.new(2025) }
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:school) { create(:school, :further_education, :fe_eligible) }

  let(:answers) {
    build(
      :further_education_payments_answers,
      :submittable,
      :with_onelogin_credentials,
      identity_confirmed_with_onelogin: true,
      logged_in_with_onelogin: true,
      onelogin_idv_first_name: "John",
      onelogin_idv_last_name: "Doe",
      onelogin_idv_full_name: "John Doe",
      onelogin_idv_date_of_birth: Date.new(1970, 1, 1),
      first_name: "John",
      surname: "Doe",
      date_of_birth: Date.new(1970, 1, 1)
    )
  }

  let(:journey_session) { create(:further_education_payments_session, answers: answers) }
  let(:form) do
    described_class.new(
      journey_session: journey_session,
      params: ActionController::Parameters.new,
      session: {},
      journey: Journeys::FurtherEducationPayments
    )
  end

  describe "#save" do
    subject { form.save }

    it "saves all answers into the Eligibility model" do
      subject
      claim = form.claim
      eligibility = form.claim.eligibility

      expect(claim.policy).to eql(Policies::FurtherEducationPayments)

      expect(claim.identity_confirmed_with_onelogin).to eq(answers.identity_confirmed_with_onelogin)
      expect(claim.logged_in_with_onelogin).to eq(answers.logged_in_with_onelogin)
      expect(claim.onelogin_credentials).to eq(answers.onelogin_credentials)
      expect(claim.onelogin_user_info).to eq(answers.onelogin_user_info)
      expect(claim.started_at).to eql(journey_session.created_at)

      expect(claim.onelogin_uid).to eql(answers.onelogin_uid)
      expect(claim.onelogin_auth_at).to eql(answers.onelogin_auth_at)
      expect(claim.onelogin_idv_at).to eql(answers.onelogin_idv_at)
      expect(claim.onelogin_idv_first_name).to eql(answers.onelogin_idv_first_name)
      expect(claim.onelogin_idv_last_name).to eql(answers.onelogin_idv_last_name)
      expect(claim.onelogin_idv_full_name).to eql(answers.onelogin_idv_full_name)
      expect(claim.onelogin_idv_date_of_birth).to eql(answers.onelogin_idv_date_of_birth)

      expect(eligibility.award_amount).to eq(answers.award_amount)
      expect(eligibility.teacher_reference_number).to eq(answers.teacher_reference_number)
      expect(eligibility.teaching_responsibilities).to eq(answers.teaching_responsibilities)
      expect(eligibility.provision_search).to eq(answers.provision_search)
      expect(eligibility.possible_school_id).to eq(answers.possible_school_id)
      expect(eligibility.school_id).to eq(answers.school_id)
      expect(eligibility.contract_type).to eq(answers.contract_type)
      expect(eligibility.fixed_term_full_year).to eq(answers.fixed_term_full_year)
      expect(eligibility.taught_at_least_one_term).to eq(answers.taught_at_least_one_term)
      expect(eligibility.teaching_hours_per_week).to eq(answers.teaching_hours_per_week)
      expect(eligibility.teaching_hours_per_week_next_term).to eq(answers.teaching_hours_per_week_next_term)
      expect(eligibility.further_education_teaching_start_year).to eq(answers.further_education_teaching_start_year)
      expect(eligibility.subjects_taught).to eq(answers.subjects_taught)
      expect(eligibility.building_construction_courses).to eq(answers.building_construction_courses)
      expect(eligibility.chemistry_courses).to eq(answers.chemistry_courses)
      expect(eligibility.computing_courses).to eq(answers.computing_courses)
      expect(eligibility.early_years_courses).to eq(answers.early_years_courses)
      expect(eligibility.engineering_manufacturing_courses).to eq(answers.engineering_manufacturing_courses)
      expect(eligibility.maths_courses).to eq(answers.maths_courses)
      expect(eligibility.physics_courses).to eq(answers.physics_courses)
      expect(eligibility.hours_teaching_eligible_subjects).to eq(answers.hours_teaching_eligible_subjects)
      expect(eligibility.teaching_qualification).to eq(answers.teaching_qualification)
      expect(eligibility.subject_to_formal_performance_action).to eq(answers.subject_to_formal_performance_action)
      expect(eligibility.subject_to_disciplinary_action).to eq(answers.subject_to_disciplinary_action)
      expect(eligibility.half_teaching_hours).to eq(answers.half_teaching_hours)
    end

    it "emails the claim provider" do
      allow(ClaimVerifierJob).to receive(:perform_later)

      travel_to DateTime.new(2025, 10, 1, 0, 0, 0) do
        perform_enqueued_jobs { subject }
      end

      claim = form.claim

      expect(claim.school.eligible_fe_provider.primary_key_contact_email_address).to(
        have_received_email(
          "9a25fe46-2ee4-4a5c-8d47-0f04f058a87d",
          recipient_name: claim.school.name,
          claimant_name: [answers.first_name, answers.surname].join(" "),
          claim_reference: claim.reference,
          claim_submission_date: "1 October 2025",
          verification_due_date: "15 October 2025",
          verification_url: Journeys::FurtherEducationPayments::Provider::SlugSequence.verify_claim_url(claim)
        )
      )

      expect(claim.eligibility.reload.provider_verification_email_last_sent_at).to eq DateTime.new(2025, 10, 1, 0, 0, 0)
    end

    it "doesn't email the provider if the claim is a duplicate" do
      allow(ClaimVerifierJob).to receive(:perform_later)

      allow(ClaimMailer).to(
        receive(:further_education_payment_provider_verification_email)
      ).and_return(double(deliver_later: nil))

      first_claim_form = described_class.new(
        journey_session: journey_session,
        params: ActionController::Parameters.new,
        session: {},
        journey: Journeys::FurtherEducationPayments
      )

      first_claim_form.save

      journey_session.update! claim: nil
      second_claim_form = described_class.new(
        journey_session: journey_session,
        params: ActionController::Parameters.new,
        session: {},
        journey: Journeys::FurtherEducationPayments
      )

      second_claim_form.save

      expect(ClaimMailer).to(
        have_received(:further_education_payment_provider_verification_email)
        .exactly(1).times
      )

      original_claim = first_claim_form.claim
      duplicate_claim = second_claim_form.claim

      expect(original_claim.eligibility.flagged_as_duplicate).to eq(false)
      expect(original_claim.eligibility.provider_verification_email_last_sent_at).not_to be_nil

      expect(duplicate_claim.eligibility.flagged_as_duplicate).to eq(true)
      expect(duplicate_claim.eligibility.provider_verification_email_last_sent_at).to be_nil
    end

    context "when one login IDV failed" do
      let(:answers) do
        build(
          :further_education_payments_answers,
          :submittable,
          :with_onelogin_credentials,
          identity_confirmed_with_onelogin: false,
          logged_in_with_onelogin: true,
          onelogin_idv_first_name: "John",
          onelogin_idv_last_name: "Doe",
          onelogin_idv_full_name: "John Doe",
          onelogin_idv_date_of_birth: Date.new(1970, 1, 1),
          first_name: "Jack",
          surname: "Doe",
          date_of_birth: Date.new(1970, 1, 1)
        )
      end

      it "does not email the provider" do
        allow(ClaimMailer).to(
          receive(:further_education_payment_provider_verification_email)
        ).and_return(double(deliver_later: nil))

        subject

        expect(ClaimMailer).not_to have_received(:further_education_payment_provider_verification_email)
      end
    end
  end
end
