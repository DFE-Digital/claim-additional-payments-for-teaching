require "rails_helper"

RSpec.describe StudentLoans::SlugSequence do
  subject(:slug_sequence) { StudentLoans::SlugSequence.new(current_claim) }

  let(:eligibility) { create(:student_loans_eligibility, :eligible) }
  let(:claim) { build(:claim, eligibility:, logged_in_with_tid:, qualifications_details_check:, dqt_teacher_status:) }
  let(:current_claim) { CurrentClaim.new(claims: [claim]) }
  let(:logged_in_with_tid) { nil }
  let(:qualifications_details_check) { nil }
  let(:dqt_teacher_status) { nil }

  describe "The sequence as defined by #slugs" do
    it "excludes the “ineligible” slug if the claim is not actually ineligible" do
      expect(claim.eligibility).not_to be_ineligible
      expect(slug_sequence.slugs).not_to include("ineligible")

      claim.eligibility.qts_award_year = "before_cut_off_date"
      expect(claim.eligibility).to be_ineligible
      expect(slug_sequence.slugs).to include("ineligible")
    end

    it "excludes “current-school” if the claimant still works at the school they are claiming against" do
      claim.eligibility.employment_status = :claim_school

      expect(slug_sequence.slugs).not_to include("current-school")
    end

    it "excludes student loan plan slugs if the claimant is not paying off a student loan" do
      claim.has_student_loan = false
      expect(slug_sequence.slugs).not_to include("student-loan-country")
      expect(slug_sequence.slugs).not_to include("student-loan-how-many-courses")
      expect(slug_sequence.slugs).not_to include("student-loan-start-date")
    end

    it "includes student loan plan slugs if the claimant is paying off a student loan" do
      claim.has_student_loan = true
      expect(slug_sequence.slugs).to include("student-loan-country")
      expect(slug_sequence.slugs).to include("student-loan-how-many-courses")
      expect(slug_sequence.slugs).to include("student-loan-start-date")
    end

    it "excludes the remaining student loan plan slugs if the claimant received their student loan in a Plan 1 country" do
      claim.has_student_loan = true

      StudentLoan::PLAN_1_COUNTRIES.each do |plan_1_country|
        claim.student_loan_country = plan_1_country
        expect(slug_sequence.slugs).to include("student-loan-country")
        expect(slug_sequence.slugs).not_to include("student-loan-how-many-courses")
        expect(slug_sequence.slugs).not_to include("student-loan-start-date")
      end

      %w[england wales].each do |variable_plan_country|
        claim.student_loan_country = variable_plan_country
        expect(slug_sequence.slugs).to include("student-loan-country")
        expect(slug_sequence.slugs).to include("student-loan-how-many-courses")
        expect(slug_sequence.slugs).to include("student-loan-start-date")
      end
    end

    it "excludes postgradute masters and postgraduate doctoral loan slugs if the claimant does not have a postgradute masters and/or doctoral loan" do
      claim.has_masters_doctoral_loan = false
      expect(slug_sequence.slugs).not_to include("masters-loan")
      expect(slug_sequence.slugs).not_to include("doctoral-loan")
    end

    it "includes postgradute masters and postgraduate doctoral loan slugs if the claimant has a postgradute masters and/or doctoral loan" do
      claim.has_masters_doctoral_loan = true
      expect(slug_sequence.slugs).to include("masters-loan")
      expect(slug_sequence.slugs).to include("doctoral-loan")
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

    context "when Teacher ID is disabled on the policy configuration" do
      before { create(:policy_configuration, :student_loans, teacher_id_enabled: false) }

      it "removes the Teacher ID-dependant slugs" do
        slugs = %w[sign-in-or-continue teacher-detail reset-claim qualification-details select-email select-mobile]
        expect(slug_sequence.slugs).not_to include(*slugs)
      end
    end

    context "when logged_in_with_tid is true" do
      let(:logged_in_with_tid) { true }

      context "when DQT returns some data" do
        let(:dqt_teacher_status) { {test: true} }

        it "adds the qualification details page" do
          expect(slug_sequence.slugs).to include("qualification-details")
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

        it "removes the qualification questions" do
          expect(slug_sequence.slugs).not_to include("qts-year")
        end
      end

      context "when the user confirmed DQT data is incorrect" do
        let(:qualifications_details_check) { false }

        it "adds the qualification questions" do
          expect(slug_sequence.slugs).to include("qts-year")
        end
      end
    end

    context "when logged_in_with_tid is false" do
      let(:logged_in_with_tid) { false }

      it "removes the qualification details page" do
        expect(slug_sequence.slugs).not_to include("qualification-details")
      end
    end

    context "when logged_in_with_tid is nil" do
      let(:logged_in_with_tid) { nil }

      it "adds the qualification details page" do
        expect(slug_sequence.slugs).to include("qualification-details")
      end
    end
  end
end
