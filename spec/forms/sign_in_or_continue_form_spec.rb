require "rails_helper"

RSpec.describe SignInOrContinueForm do
  shared_examples "sign_in_or_continue_form" do |journey|
    let(:journey_session) do
      build(
        :"#{journey::I18N_NAMESPACE}_session",
        answers: attributes_for(
          :"#{journey::I18N_NAMESPACE}_answers",
          :with_details_from_dfe_identity
        )
      )
    end

    let(:form) do
      described_class.new(
        journey: journey,
        journey_session: journey_session,
        params: params
      )
    end

    describe "validations" do
      let(:teacher_id_user_info) { {} }

      subject { form }

      describe "teacher_id_user_info" do
        context "when the teacher skipped dfe identity" do
          context "when `nil" do
            let(:params) do
              ActionController::Parameters.new(
                claim: {
                  logged_in_with_tid: false,
                  details_check: nil
                }
              )
            end

            it { is_expected.to be_valid }
          end
        end

        context "when the teacher signed in with dfe identity" do
          context "when `nil" do
            let(:params) do
              ActionController::Parameters.new(
                claim: {
                  logged_in_with_tid: true,
                  details_check: nil
                }
              )
            end

            it { is_expected.not_to be_valid }
          end

          context "when `true`" do
            let(:params) do
              ActionController::Parameters.new(
                claim: {
                  logged_in_with_tid: true,
                  details_check: true
                }
              )
            end

            it { is_expected.to be_valid }
          end

          context "when `false`" do
            let(:params) do
              ActionController::Parameters.new(
                claim: {
                  logged_in_with_tid: true,
                  details_check: false
                }
              )
            end

            it { is_expected.to be_valid }
          end
        end
      end
    end

    describe "#save" do
      before do
        allow(Dqt::RetrieveClaimQualificationsData).to(receive(:call))

        form.save
      end

      context "when skipped dfe identity" do
        let(:teacher_id_user_info) { {} }

        let(:params) do
          ActionController::Parameters.new(
            claim: {
              logged_in_with_tid: false
            }
          )
        end

        it "sets logged in with tid to false" do
          expect(journey_session.answers.logged_in_with_tid).to eq(false)
        end

        it "leaves details check as nil" do
          expect(journey_session.answers.details_check).to eq(nil)
        end

        it "resets any attributes that were set from dfe identity" do
          expect(journey_session.answers.first_name).to eq("")
          expect(journey_session.answers.surname).to eq("")
          expect(journey_session.answers.teacher_reference_number).to eq("")
          expect(journey_session.answers.date_of_birth).to eq(nil)
          expect(journey_session.answers.national_insurance_number).to eq("")
        end

        it "resets teacher_id_user_info" do
          expect(journey_session.answers.teacher_id_user_info).to eq({})
        end

        it "doesn't retrieve the claim's qualifications data" do
          expect(Dqt::RetrieveClaimQualificationsData).not_to(
            have_received(:call)
          )
        end
      end

      context "when signed in with dfe identity" do
        context "when the teacher indicates that the details are incorrect" do
          let(:params) do
            ActionController::Parameters.new(
              claim: {
                logged_in_with_tid: true,
                details_check: false,
                teacher_id_user_info_attributes: teacher_id_user_info
              }
            )
          end

          let(:teacher_id_user_info) do
            {
              given_name: "Seymour",
              family_name: "Skinner",
              birthdate: "1953-10-30",
              trn: "1234567",
              ni_number: "AB123456C",
              trn_match_ni_number: true,
              email: "seymour.skinner@springfieldelementry.edu",
              email_verified: true,
              phone_number: "0123456789"
            }
          end

          # Unsure if we should keep this behaviour but this is what it
          # currently does
          it "sets logged in with tid to false" do
            expect(journey_session.answers.logged_in_with_tid).to eq(false)
          end

          it "sets details check to false" do
            expect(journey_session.answers.details_check).to eq(false)
          end

          it "resets any attributes that were set from dfe identity" do
            expect(journey_session.answers.first_name).to eq("")
            expect(journey_session.answers.surname).to eq("")
            expect(journey_session.answers.teacher_reference_number).to eq("")
            expect(journey_session.answers.date_of_birth).to eq(nil)
            expect(journey_session.answers.national_insurance_number).to eq("")
          end

          # Unsure if we should keep this behaviour but this is what it
          # currently does
          it "keeps the details from teacher_id_user_info" do
            expect(
              journey_session.answers.teacher_id_user_info.symbolize_keys
            ).to(eq(teacher_id_user_info))
          end

          it "doesn't retrieve the claim's qualifications data" do
            expect(Dqt::RetrieveClaimQualificationsData).not_to(
              have_received(:call)
            )
          end
        end

        context "when the teacher indicates that the details are correct" do
          let(:params) do
            ActionController::Parameters.new(
              claim: {
                logged_in_with_tid: true,
                details_check: true,
                teacher_id_user_info_attributes: teacher_id_user_info
              }
            )
          end

          context "when the details don't validate" do
            let(:teacher_id_user_info) do
              {
                given_name: "Seymour",
                family_name: "Skinner",
                birthdate: "1953-10-30",
                ni_number: "AB123456C",
                trn: nil,
                trn_match_ni_number: true,
                email: "seymour.skinner@springfieldelementry.edu",
                email_verified: true,
                phone_number: "0123456789"
              }
            end

            it "sets logged in with tid to true" do
              expect(journey_session.answers.logged_in_with_tid).to eq(true)
            end

            # Unsure if we should keep this behaviour but this is what it
            # currently does
            it "sets details check to false" do
              expect(journey_session.answers.details_check).to eq(false)
            end

            # Unsure if we should keep this behaviour but this is what it
            # currently does
            it "doesnt resets any attributes that were set from dfe identity" do
              expect(journey_session.answers.first_name).to eq("Jo")
              expect(journey_session.answers.surname).to eq("Bloggs")
              expect(
                journey_session.answers.teacher_reference_number
              ).to be_present
              expect(
                journey_session.answers.date_of_birth
              ).to eq(20.years.ago.to_date)
              expect(
                journey_session.answers.national_insurance_number
              ).to be_present
            end

            it "keeps the details from teacher_id_user_info" do
              expect(
                journey_session.answers.teacher_id_user_info.symbolize_keys
              ).to(eq(teacher_id_user_info))
            end

            it "doesn't retrieve the claim's qualifications data" do
              expect(Dqt::RetrieveClaimQualificationsData).not_to(
                have_received(:call)
              )
            end
          end

          context "when the details validate" do
            let(:teacher_id_user_info) do
              {
                given_name: "Seymour",
                family_name: "Skinner",
                birthdate: "1953-10-30",
                trn: "1234567",
                ni_number: "AB123456C",
                trn_match_ni_number: true,
                email: "seymour.skinner@springfieldelementry.edu",
                email_verified: true,
                phone_number: "0123456789"
              }
            end

            it "sets logged in with tid to true" do
              expect(journey_session.answers.logged_in_with_tid).to eq(true)
            end

            it "sets details check to true" do
              expect(journey_session.answers.details_check).to eq(true)
            end

            it "updates the claim with details from dfe identity" do
              expect(journey_session.answers.first_name).to eq("Seymour")
              expect(journey_session.answers.surname).to eq("Skinner")
              expect(
                journey_session.answers.teacher_reference_number
              ).to(eq("1234567"))
              expect(
                journey_session.answers.date_of_birth
              ).to(eq(Date.new(1953, 10, 30)))
              expect(
                journey_session.answers.national_insurance_number
              ).to(eq("AB123456C"))
            end

            it "keeps the details from teacher_id_user_info" do
              expect(
                journey_session.answers.teacher_id_user_info.symbolize_keys
              ).to(eq(teacher_id_user_info))
            end

            it "retrieves the claim's qualifications data" do
              expect(Dqt::RetrieveClaimQualificationsData).to(
                have_received(:call).with(journey_session)
              )
            end
          end
        end
      end
    end
  end

  describe "for TeacherStudentLoanReimbursement journey" do
    include_examples(
      "sign_in_or_continue_form",
      Journeys::TeacherStudentLoanReimbursement
    )
  end

  describe "for TargetedRetentionIncentivePayments journey" do
    include_examples(
      "sign_in_or_continue_form",
      Journeys::TargetedRetentionIncentivePayments
    )
  end
end
