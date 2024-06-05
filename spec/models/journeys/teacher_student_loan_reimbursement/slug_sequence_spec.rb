require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::SlugSequence do
  subject(:slug_sequence) { described_class.new(current_claim, journey_session) }

  let(:eligibility) { create(:student_loans_eligibility, :eligible) }
  let(:claim) { build(:claim, eligibility:, qualifications_details_check:) }
  let(:current_claim) { CurrentClaim.new(claims: [claim]) }
  let(:journey_session) do
    build(
      :student_loans_session,
      answers: {
        logged_in_with_tid: logged_in_with_tid,
        details_check: details_check,
        dqt_teacher_status: dqt_teacher_status
      }
    )
  end
  let(:logged_in_with_tid) { nil }
  let(:details_check) { nil }
  let(:qualifications_details_check) { nil }
  let(:dqt_teacher_status) { nil }

  describe "The sequence as defined by #slugs" do
    it "excludes the “ineligible” slug if the claim is not actually ineligible" do
      expect(claim.eligibility).not_to be_ineligible
      expect(slug_sequence.slugs).not_to include("ineligible")
    end

    it "includes the “ineligible” slug if the claim is actually ineligible" do
      claim.eligibility.update! qts_award_year: "before_cut_off_date"
      expect(claim.eligibility.reload).to be_ineligible
      expect(slug_sequence.slugs).to include("ineligible")
    end

    it "excludes “current-school” if the claimant still works at the school they are claiming against" do
      journey_session.answers.employment_status = :claim_school

      expect(slug_sequence.slugs).not_to include("current-school")
    end

    context "when claim payment details are 'personal bank account'" do
      it "excludes the 'building-society-account' slug" do
        journey_session.answers.bank_or_building_society = :personal_bank_account

        expect(slug_sequence.slugs).not_to include("building-society-account")
      end
    end

    context "when claim payment details are 'building society'" do
      it "excludes the 'personal-bank-account' slug" do
        journey_session.answers.bank_or_building_society = :building_society

        expect(slug_sequence.slugs).not_to include("personal-bank-account")
      end
    end

    context "when 'provide_mobile_number' is 'No'" do
      it "excludes the 'mobile-number' slug" do
        journey_session.answers.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-number")
      end

      it "excludes the 'mobile-verification' slug" do
        journey_session.answers.provide_mobile_number = false

        expect(slug_sequence.slugs).not_to include("mobile-verification")
      end
    end

    context "when 'provide_mobile_number' is 'Yes'" do
      it "includes the 'mobile-number' slug" do
        journey_session.answers.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-number")
      end

      it "includes the 'mobile-verification' slug" do
        journey_session.answers.provide_mobile_number = true

        expect(slug_sequence.slugs).to include("mobile-verification")
      end
    end

    context "when Teacher ID is disabled on the policy configuration" do
      before { create(:journey_configuration, :student_loans, teacher_id_enabled: false) }

      it "removes the Teacher ID-dependant slugs" do
        slugs = %w[sign-in-or-continue reset-claim qualification-details select-email select-mobile]
        expect(slug_sequence.slugs).not_to include(*slugs)
      end
    end

    context "when logged_in_with_tid and details_check are true" do
      let(:logged_in_with_tid) { true }
      let(:details_check) { true }
      let(:qts_award_date) { "test" }

      before do
        allow_any_instance_of(
          Journeys::TeacherStudentLoanReimbursement::SessionAnswers
        ).to receive(:dqt_teacher_record).and_return(
          double(qts_award_date:, has_no_data_for_claim?: false)
        )
      end

      context "when DQT returns some data" do
        let(:dqt_teacher_status) { {test: true} }

        it "adds the qualification details page" do
          expect(slug_sequence.slugs).to include("qualification-details")
        end

        context "when the DQT payload is missing all required data" do
          let(:dqt_teacher_status) { {} }

          it "removes the qualification details page" do
            expect(slug_sequence.slugs).not_to include("qualification-details")
          end

          it "does not remove the relevant pages" do
            expect(slug_sequence.slugs).to include("qts-year")
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
            expect(slug_sequence.slugs).not_to include("qts-year")
          end
        end

        context "when the DQT payload is missing some data" do
          let(:qts_award_date) { nil }

          it "does not remove the relevant pages" do
            expect(slug_sequence.slugs).to include("qts-year")
          end
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

      it "does not add the qualification details page" do
        expect(slug_sequence.slugs).not_to include("qualification-details")
      end
    end
  end
end
