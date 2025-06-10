require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::SlugSequence do
  before { create(:journey_configuration, :student_loans) }

  subject(:slug_sequence) { described_class.new(journey_session) }

  let(:journey_session) do
    build(
      :student_loans_session,
      answers: {
        logged_in_with_tid: logged_in_with_tid,
        details_check: details_check,
        dqt_teacher_status: dqt_teacher_status,
        qualifications_details_check: qualifications_details_check
      }
    )
  end
  let(:logged_in_with_tid) { nil }
  let(:details_check) { nil }
  let(:qualifications_details_check) { nil }
  let(:dqt_teacher_status) { nil }

  describe "The sequence as defined by #slugs" do
    it "excludes “current-school” if the claimant still works at the school they are claiming against" do
      journey_session.answers.employment_status = :claim_school

      expect(slug_sequence.slugs).not_to include("current-school")
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
      before do
        Journeys::TeacherStudentLoanReimbursement.configuration.update!(
          teacher_id_enabled: false
        )
      end

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
        allow(Policies::StudentLoans::DqtRecord).to receive(:new).and_return(
          instance_double(
            "Policies::StudentLoans::DqtRecord",
            qts_award_date: qts_award_date,
            has_no_data_for_claim?: false
          )
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
        let(:dqt_teacher_status) { {test: true} }

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
