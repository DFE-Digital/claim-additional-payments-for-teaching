require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::SlugSequence do
  subject(:slug_sequence) { described_class.new(current_claim, journey_session) }

  let(:eligibility) { create(:early_career_payments_eligibility, :eligible) }
  let(:eligibility_lup) { create(:levelling_up_premium_payments_eligibility, :eligible) }

  let(:claim) do
    create(
      :claim,
      :skipped_tid,
      policy: Policies::EarlyCareerPayments,
      academic_year: AcademicYear.new(2021),
      eligibility: eligibility,
      qualifications_details_check:
    )
  end
  let(:lup_claim) { create(:claim, :skipped_tid, policy: Policies::LevellingUpPremiumPayments, academic_year: AcademicYear.new(2021), eligibility: eligibility_lup) }
  let(:current_claim) { CurrentClaim.new(claims: [claim, lup_claim]) }
  let(:journey_session) do
    create(
      :additional_payments_session,
      answers: {
        logged_in_with_tid: logged_in_with_tid,
        details_check: details_check,
        dqt_teacher_status: dqt_teacher_status
      }
    )
  end
  let(:teacher_id_enabled) { true }
  let(:logged_in_with_tid) { nil }
  let(:details_check) { nil }
  let(:dqt_teacher_status) { nil }
  let(:qualifications_details_check) { nil }

  describe "The sequence as defined by #slugs" do
    before { create(:journey_configuration, :additional_payments, teacher_id_enabled:) }

    it "excludes the 'ineligible' slug if the claim's eligibility is undetermined" do
      expect(slug_sequence.slugs).not_to include("ineligible")
    end

    it "excludes supply teacher detail slugs if they aren't a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = false

      expect(slug_sequence.slugs).not_to include("entire-term-contract", "employed-directly")
    end

    it "includes supply teacher detail slugs if they are a supply teacher" do
      claim.eligibility.employed_as_supply_teacher = true

      expect(slug_sequence.slugs).to include("entire-term-contract", "employed-directly")
    end

    shared_context "logged in with Teacher ID and DQT qualifications retrieved" do
      let(:logged_in_with_tid) { true }
      let(:itt_academic_year_for_claim) { "test" }
      let(:route_into_teaching) { "test" }
      let(:eligible_itt_subject_for_claim) { "test" }
      let(:eligible_degree_code?) { true }
      let(:has_no_data_for_claim?) { false }
      let(:eligible_induction?) { true }

      let(:early_career_payments_dqt_record_double) { double(itt_academic_year_for_claim:, route_into_teaching:, eligible_itt_subject_for_claim:, has_no_data_for_claim?: has_no_data_for_claim?, eligible_induction?: eligible_induction?) }
      let(:levelling_up_premium_payments_dqt_record_double) { double(itt_academic_year_for_claim:, route_into_teaching:, eligible_itt_subject_for_claim:, has_no_data_for_claim?: has_no_data_for_claim?, eligible_degree_code?: eligible_degree_code?) }

      before do
        allow_any_instance_of(
          Journeys::AdditionalPaymentsForTeaching::SessionAnswers
        ).to(
          receive(:early_career_payments_dqt_teacher_record)
          .and_return(early_career_payments_dqt_record_double)
        )
        allow_any_instance_of(
          Journeys::AdditionalPaymentsForTeaching::SessionAnswers
        ).to(
          receive(:levelling_up_premium_payments_dqt_reacher_record)
          .and_return(levelling_up_premium_payments_dqt_record_double)
        )
      end
    end

    context "when logged_in_with_tid is true" do
      include_context "logged in with Teacher ID and DQT qualifications retrieved"

      context "when the ECP DQT record does not contain eligible induction data" do
        let(:eligible_induction?) { false }

        it "includes the induction completed question" do
          expect(slug_sequence.slugs).to include("induction-completed")
        end
      end

      context "when the ECP DQT record contains eligible induction data" do
        let(:eligible_induction?) { true }

        it "removes the induction completed question" do
          expect(slug_sequence.slugs).not_to include("induction-completed")
        end
      end
    end

    context "when logged_in_with_tid and details_check are true" do
      include_context "logged in with Teacher ID and DQT qualifications retrieved"
      let(:details_check) { true }

      context "when DQT returns some data" do
        let(:dqt_teacher_status) { {"test" => "test"} }

        it "adds the qualification details page" do
          expect(slug_sequence.slugs).to include("qualification-details")
        end

        context "when the DQT payload is missing all required data" do
          let(:has_no_data_for_claim?) { true }

          it "removes the qualification details page" do
            expect(slug_sequence.slugs).not_to include("qualification-details")
          end

          it "does not remove the relevant pages" do
            expect(slug_sequence.slugs).to include("qualification")
            expect(slug_sequence.slugs).to include("eligible-itt-subject")
            expect(slug_sequence.slugs).to include("itt-year")
          end
        end
      end

      context "when the DQT payload is empty" do
        let(:dqt_teacher_status) { {} }

        it "removes the qualification details page" do
          expect(slug_sequence.slugs).not_to include("qualification-details")
        end
      end

      context "when the user confirmed DQT data is correct" do
        let(:qualifications_details_check) { true }

        context "when the DQT record contains all required data" do
          it "removes the qualification questions" do
            expect(slug_sequence.slugs).not_to include("qualification", "itt-year", "eligible-itt-subject", "eligible-degree-subject")
          end
        end

        context "when the DQT payload is missing some data" do
          let(:itt_academic_year_for_claim) { nil }

          it "does not remove the relevant pages" do
            expect(slug_sequence.slugs).not_to include("qualification")
            expect(slug_sequence.slugs).not_to include("eligible-itt-subject")
            expect(slug_sequence.slugs).to include("itt-year")
          end
        end
      end

      context "when the user confirmed DQT data is incorrect" do
        let(:qualifications_details_check) { false }

        it "adds the qualification questions" do
          expect(slug_sequence.slugs).to include("qualification", "itt-year", "eligible-itt-subject")
        end
      end

      it "includes teacher reference number slug if teacher reference number is nil" do
        journey_session.answers.teacher_reference_number = nil

        expect(slug_sequence.slugs).to include("teacher-reference-number")
      end

      it "does not include teacher reference number slug if teacher reference number is not nil" do
        journey_session.answers.teacher_reference_number = "1234567"

        expect(slug_sequence.slugs).not_to include("teacher-reference-number")
      end

      it "skips personal-details page if all details were provided and valid from TID" do
        dob = 30.years.ago.to_date
        journey_session.answers.teacher_id_user_info = {
          "given_name" => "John",
          "family_name" => "Doe",
          "birthdate" => dob.to_s,
          "ni_number" => "JH001234D"
        }

        journey_session.answers.first_name = "John"
        journey_session.answers.surname = "Doe"
        journey_session.answers.date_of_birth = dob
        journey_session.answers.national_insurance_number = "JH001234D"

        journey_session.answers.answered = %w[
          first_name
          surname
          date_of_birth
          national_insurance_number
        ]

        expect(slug_sequence.slugs).not_to include("personal-details")
      end

      it "includes personal-details page if nino is missing" do
        journey_session.answers.first_name = "John"
        journey_session.answers.surname = "Doe"
        journey_session.answers.date_of_birth = 30.years.ago.to_date
        journey_session.answers.national_insurance_number = nil

        journey_session.answers.answered = %w[
          first_name
          surname
          date_of_birth
          national_insurance_number
        ]

        expect(slug_sequence.slugs).to include("personal-details")
      end

      it "includes personal-details page if name is missing" do
        journey_session.answers.first_name = nil
        journey_session.answers.surname = nil
        journey_session.answers.date_of_birth = 30.years.ago.to_date
        journey_session.answers.national_insurance_number = "JH001234D"

        journey_session.answers.answered = %w[
          first_name
          surname
          date_of_birth
          national_insurance_number
        ]

        expect(slug_sequence.slugs).to include("personal-details")
      end

      it "includes personal-details page if dob is missing" do
        journey_session.answers.first_name = "John"
        journey_session.answers.surname = "Doe"
        journey_session.answers.date_of_birth = nil
        journey_session.answers.national_insurance_number = "JH001234D"

        journey_session.answers.answered = %w[
          first_name
          surname
          date_of_birth
          national_insurance_number
        ]

        expect(slug_sequence.slugs).to include("personal-details")
      end
    end

    context "when logged_in_with_tid is false" do
      let(:logged_in_with_tid) { false }

      it "removes the qualification details page" do
        expect(slug_sequence.slugs).not_to include("qualification-details")
      end

      it "includes teacher reference number slug if teacher reference number is nil" do
        claim.teacher_reference_number = nil

        expect(slug_sequence.slugs).to include("teacher-reference-number")
      end

      it "includes teacher reference number slug if teacher reference number is not nil" do
        claim.teacher_reference_number = "1234567"

        expect(slug_sequence.slugs).to include("teacher-reference-number")
      end
    end

    context "when logged_in_with_tid is nil" do
      let(:logged_in_with_tid) { nil }

      it "removes the qualification details page" do
        expect(slug_sequence.slugs).not_to include("qualification-details")
      end
    end

    context "when 'provide_mobile_number' is 'No'" do
      it "excludes the 'mobile-number' slug" do
        claim.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-number")
      end

      it "excludes the 'mobile-verification' slug" do
        claim.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-verification")
      end
    end

    context "when 'provide_mobile_number' is 'Yes'" do
      it "includes the 'mobile-number' slug" do
        claim.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-number")
      end

      it "includes the 'mobile-verification' slug" do
        claim.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-verification")
      end
    end

    context "when claim is eligible" do
      let(:eligibility) { build(:early_career_payments_eligibility, :eligible) }

      it "includes the 'eligibility_confirmed' slug" do
        expect(slug_sequence.slugs).to include("eligibility-confirmed")
      end
    end

    context "when claim is ineligible" do
      let(:eligibility) { build(:early_career_payments_eligibility, :ineligible) }
      let(:eligibility_lup) { build(:levelling_up_premium_payments_eligibility, :ineligible) }

      it "includes the 'ineligible' slug" do
        expect(slug_sequence.slugs).to include("ineligible")
      end

      it "excludes the 'eligibility-confirmed' slug" do
        expect(slug_sequence.slugs).not_to include("eligibility-confirmed")
      end
    end

    context "when claim is not eligible later" do
      let(:eligibility) do
        build(
          :early_career_payments_eligibility,
          :eligible,
          eligible_itt_subject: "mathematics",
          itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2018))
        )
      end

      it "excludes the 'eligible-later' slug" do
        expect(slug_sequence.slugs).not_to include("eligible-later")
      end
    end

    context "when claim payment details are 'personal bank account'" do
      it "excludes the 'building-society-account' slug" do
        claim.bank_or_building_society = :personal_bank_account

        expect(slug_sequence.slugs).not_to include("building-society-account")
      end
    end

    context "when claim payment details are 'building society'" do
      it "excludes the 'personal-bank-account' slug" do
        claim.bank_or_building_society = :building_society

        expect(slug_sequence.slugs).not_to include("personal-bank-account")
      end
    end

    context "when Teacher ID is disabled on the policy configuration" do
      let(:teacher_id_enabled) { false }

      it "removes the Teacher ID-dependant slugs" do
        slugs = %w[sign-in-or-continue reset-claim qualification-details correct-school select-email select-mobile]
        expect(slug_sequence.slugs).not_to include(*slugs)
      end
    end
  end

  describe "eligibility affect on slugs" do
    let(:ecp_claim) { build(:claim, policy: Policies::EarlyCareerPayments, eligibility_trait: ecp_eligibility) }
    let(:lup_claim) { build(:claim, policy: Policies::LevellingUpPremiumPayments, eligibility_trait: lup_eligibility) }
    let(:current_claim) { CurrentClaim.new(claims: [ecp_claim, lup_claim]) }
    let(:journey_session) { build(:additional_payments_session) }

    subject { described_class.new(current_claim, journey_session).slugs }

    context "current claim is :eligible_now" do
      let(:ecp_eligibility) { :eligible_later }
      let(:lup_eligibility) { :eligible_now }

      it { is_expected.to include("eligibility-confirmed") }
      it { is_expected.not_to include("eligible-later", "ineligible") }
    end

    context "current claim is :eligible_later" do
      let(:ecp_eligibility) { :ineligible }
      let(:lup_eligibility) { :eligible_later }

      it { is_expected.to include("eligible-later") }
      it { is_expected.not_to include("eligibility-confirmed") }
    end

    context "current claim is :ineligible" do
      let(:ecp_eligibility) { :ineligible }
      let(:lup_eligibility) { :ineligible }

      it { is_expected.to include("ineligible") }
      it { is_expected.not_to include("eligibility-confirmed", "eligible-later") }
    end
  end
end
