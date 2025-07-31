require "rails_helper"

RSpec.describe Journeys::TargetedRetentionIncentivePayments::SlugSequence do
  before do
    create(:journey_configuration, :targeted_retention_incentive_payments)
  end

  let(:journey_session) do
    create(:targeted_retention_incentive_payments_session, answers: {})
  end

  let(:slugs) { described_class.new(journey_session).slugs }

  let(:eligibility_slugs) do
    slugs.select do |slug|
      described_class::ELIGIBILITY_SLUGS.include?(slug)
    end
  end

  let(:personal_details_slugs) do
    slugs.select do |slug|
      described_class::PERSONAL_DETAILS_SLUGS.include?(slug)
    end
  end

  let(:payment_details_slugs) do
    slugs.select do |slug|
      described_class::PAYMENT_DETAILS_SLUGS.include?(slug)
    end
  end

  let(:results_slugs) do
    slugs.select do |slug|
      described_class::RESULTS_SLUGS.include?(slug)
    end
  end

  describe "#slugs" do
    context "eligibility slugs" do
      subject { eligibility_slugs }

      context "non tid, non trainee, non supply teacher, eligible degree subject" do
        it do
          is_expected.to match_array %w[
            check-eligibility-intro
            sign-in-or-continue
            current-school
            nqt-in-academic-year-after-itt
            supply-teacher
            poor-performance
            qualification
            itt-year
            eligible-itt-subject
            teaching-subject-now
            check-your-answers-part-one
            eligibility-confirmed
          ]
        end
      end

      context "when a supply teacher" do
        before do
          journey_session.answers.assign_attributes(
            employed_as_supply_teacher: true
          )

          journey_session.save!
        end

        it do
          is_expected.to match_array %w[
            check-eligibility-intro
            sign-in-or-continue
            current-school
            nqt-in-academic-year-after-itt
            supply-teacher
            entire-term-contract
            employed-directly
            poor-performance
            qualification
            itt-year
            eligible-itt-subject
            teaching-subject-now
            check-your-answers-part-one
            eligibility-confirmed
          ]
        end
      end

      context "when a trainee teacher" do
        before do
          journey_session.answers.assign_attributes(
            trainee_teacher: true
          )

          journey_session.save!
        end

        it do
          is_expected.to match_array %w[
            check-eligibility-intro
            sign-in-or-continue
            current-school
            nqt-in-academic-year-after-itt
            eligible-itt-subject
            future-eligibility
          ]
        end
      end

      context "when a trainee teacher with non-eligible subject" do
        before do
          journey_session.answers.assign_attributes(
            trainee_teacher: true,
            eligible_itt_subject: "none_of_the_above"
          )

          journey_session.save!
        end

        it do
          is_expected.to match_array %w[
            check-eligibility-intro
            sign-in-or-continue
            current-school
            nqt-in-academic-year-after-itt
            eligible-itt-subject
            eligible-degree-subject
            future-eligibility
          ]
        end
      end

      context "when not eligible for ITT subject" do
        before do
          journey_session.answers.assign_attributes(
            eligible_itt_subject: "none_of_the_above"
          )

          journey_session.save!
        end

        it { is_expected.to include("eligible-degree-subject") }
      end

      context "when logged in with teacher ID" do
        before do
          journey_session.answers.assign_attributes(
            logged_in_with_tid: true
          )

          journey_session.save!
        end

        describe "selecting school" do
          before do
            la = create(:local_authority)

            tps_record = create(
              :teachers_pensions_service,
              school_urn: 123456,
              teacher_reference_number: 1234567,
              end_date: 1.day.from_now,
              la_urn: la.code
            )

            create(
              :school,
              establishment_number: tps_record.school_urn,
              local_authority: la
            )
          end

          context "when has a recent tps school" do
            before do
              journey_session.answers.assign_attributes(
                details_check: true,
                logged_in_with_tid: true,
                teacher_id_user_info: {
                  "trn" => "1234567"
                },
                teacher_reference_number: "1234567"
              )

              journey_session.save!
            end

            it { is_expected.to include("correct-school") }
          end

          context "when no recent tps school" do
            before do
              journey_session.answers.assign_attributes(
                details_check: false,
                teacher_id_user_info: {
                  "trn" => "1234567"
                }
              )

              journey_session.save!
            end

            it { is_expected.not_to include("correct-school") }
          end

          context "when choosing the recent tps school" do
            before do
              journey_session.answers.assign_attributes(
                school_somewhere_else: false
              )

              journey_session.save!
            end

            it { is_expected.not_to include("current-school") }
          end

          context "when rejecting the recent tps school" do
            before do
              journey_session.answers.assign_attributes(
                school_somewhere_else: true
              )

              journey_session.save!
            end

            it { is_expected.to include("current-school") }
          end
        end

        describe "qualification details" do
          context "when no DQT data returned" do
            it { is_expected.to include("qualification") }
            it { is_expected.not_to include("qualification-details") }
            it { is_expected.to include("itt-year") }
            it { is_expected.to include("eligible-itt-subject") }
          end

          context "when route into teaching returned" do
            before do
              journey_session.answers.assign_attributes(
                dqt_teacher_status: {
                  initial_teacher_training: {
                    qualification: "Professional Graduate Diploma in Education" # route_into_teaching
                  }
                }
              )

              journey_session.save!
            end

            context "when DQT data is confirmed" do
              before do
                journey_session.answers.assign_attributes(
                  details_check: true,
                  qualifications_details_check: true
                )

                journey_session.save!
              end

              it { is_expected.not_to include("qualification") }
            end

            context "when DQT data is not confirmed" do
              it { is_expected.to include("qualification") }
            end
          end

          context "when ITT year is returned" do
            before do
              journey_session.answers.assign_attributes(
                dqt_teacher_status: {
                  # qualification maps to postgraduate so we read the
                  # qualification date from the itt programme start date
                  initial_teacher_training: {
                    qualification: "Professional Graduate Diploma in Education", # route_into_teaching
                    programme_start_date: "2024-01-01T00:00:00"
                  }
                }
              )

              journey_session.save!
            end

            context "when DQT data is confirmed" do
              before do
                journey_session.answers.assign_attributes(
                  details_check: true,
                  qualifications_details_check: true
                )

                journey_session.save!
              end

              it { is_expected.not_to include("itt-year") }
            end

            context "when DQT data is not confirmed" do
              it { is_expected.to include("itt-year") }
            end
          end

          context "when eligible itt subject is returned" do
            before do
              journey_session.answers.assign_attributes(
                dqt_teacher_status: {
                  initial_teacher_training: {
                    subject1: "mathematics", # eligible_itt_subject_for_claim
                    subject1_code: "G100"
                  }
                }
              )

              journey_session.save!
            end

            context "when DQT data is confirmed" do
              before do
                journey_session.answers.assign_attributes(
                  details_check: true,
                  qualifications_details_check: true
                )

                journey_session.save!
              end

              it { is_expected.not_to include("eligible-itt-subject") }
            end

            context "when DQT data is not confirmed" do
              it { is_expected.to include("eligible-itt-subject") }
            end
          end
        end
      end
    end

    context "personal details slugs" do
      subject { personal_details_slugs }

      context "with default settings" do
        it do
          is_expected.to match_array %w[
            information-provided
            personal-details
            postcode-search
            select-home-address
            email-address
            email-verification
            provide-mobile-number
            mobile-number
            mobile-verification
          ]
        end
      end

      context "when a trainee teacher" do
        before do
          journey_session.answers.assign_attributes(
            trainee_teacher: true
          )

          journey_session.save!
        end

        it { is_expected.to be_empty }
      end

      context "when ordnance survey error occurs" do
        before do
          journey_session.answers.assign_attributes(
            ordnance_survey_error: true
          )

          journey_session.save!
        end

        it { is_expected.not_to include("select-home-address") }
      end

      context "when the user wants to enter their address manually" do
        before do
          journey_session.answers.assign_attributes(
            skip_postcode_search: true
          )

          journey_session.save!
        end

        it { is_expected.not_to include("select-home-address") }
      end

      context "when email is verified" do
        before do
          journey_session.answers.assign_attributes(
            email_verified: true
          )

          journey_session.save!
        end

        it { is_expected.not_to include("email-verification") }
      end

      context "when user doesn't want to provide mobile number" do
        before do
          journey_session.answers.assign_attributes(
            provide_mobile_number: false
          )

          journey_session.save!
        end

        it { is_expected.not_to include("mobile-number") }
        it { is_expected.not_to include("mobile-verification") }
      end

      context "when logged in with teacher id" do
        before do
          journey_session.answers.assign_attributes(
            logged_in_with_tid: true
          )

          journey_session.save!
        end

        context "when email is from teacher id" do
          before do
            journey_session.answers.assign_attributes(
              details_check: true,
              teacher_id_user_info: {
                "email" => "test@example.com"
              }
            )

            journey_session.save!
          end

          it { is_expected.to include("select-email") }
        end

        context "when email address check is true" do
          before do
            journey_session.answers.assign_attributes(
              email_address_check: true
            )

            journey_session.save!
          end

          it { is_expected.not_to include("email-address") }
        end

        context "when email verification is true" do
          before do
            journey_session.answers.assign_attributes(
              email_verified: true
            )

            journey_session.save!
          end

          it { is_expected.not_to include("email-verification") }
        end

        context "when mobile is from teacher_id" do
          before do
            journey_session.answers.assign_attributes(
              logged_in_with_tid: true,
              teacher_id_user_info: {
                "phone_number" => "07700900000"
              }
            )

            journey_session.save!
          end

          context "when details check is true" do
            before do
              journey_session.answers.assign_attributes(
                details_check: true
              )

              journey_session.save
            end

            it { is_expected.to include("select-mobile") }
            it { is_expected.not_to include("provide-mobile") }
          end

          context "when details check is false" do
            before do
              journey_session.answers.assign_attributes(
                details_check: false
              )

              journey_session.save
            end

            it { is_expected.not_to include("select-mobile") }
            it { is_expected.to include("provide-mobile-number") }
          end
        end

        context "when mobile check is set to use Teacher ID mobile" do
          before do
            journey_session.answers.assign_attributes(
              logged_in_with_tid: true,
              provide_mobile_number: true,
              mobile_number: "01234567890",
              mobile_check: "use"
            )

            journey_session.save!
          end

          it { is_expected.not_to include("mobile-number") }
          it { is_expected.not_to include("mobile-verification") }
        end

        context "when mobile check is set to use alternative mobile" do
          before do
            journey_session.answers.assign_attributes(
              logged_in_with_tid: true,
              provide_mobile_number: true,
              mobile_number: "01234567890",
              mobile_check: "alternative"
            )

            journey_session.save!
          end

          it { is_expected.to include("mobile-number") }
          it { is_expected.to include("mobile-verification") }
        end

        context "when mobile check is declined" do
          before do
            journey_session.answers.assign_attributes(
              logged_in_with_tid: true,
              provide_mobile_number: true,
              mobile_number: "01234567890",
              mobile_check: "declined"
            )

            journey_session.save!
          end

          it { is_expected.not_to include("mobile-number") }
          it { is_expected.not_to include("mobile-verification") }
        end
      end

      context "when not logged in with teacher id" do
        it { is_expected.to include("personal-details") }
      end

      context "when personal details are from TID" do
        before do
          journey_session.answers.assign_attributes(
            logged_in_with_tid: true,
            details_check: true
          )

          journey_session.save!
        end

        context "when details from teacher id are missing" do
          before do
            journey_session.answers.assign_attributes(
              first_name: "Seymour",
              surname: "Skinner",
              date_of_birth: Date.new(1953, 10, 23),
              national_insurance_number: ""
            )

            journey_session.save!
          end

          it { is_expected.to include("personal-details") }
        end

        context "when details from teacher id are present" do
          before do
            journey_session.answers.assign_attributes(
              first_name: "Seymour",
              surname: "Skinner",
              date_of_birth: Date.new(1953, 10, 23),
              national_insurance_number: "QQ123456C"
            )

            journey_session.save!
          end

          it { is_expected.not_to include("personal-details") }
        end
      end
    end

    context "payment and results slugs" do
      subject { [payment_details_slugs, results_slugs].flatten }

      context "when a trainee teacher" do
        before do
          journey_session.answers.assign_attributes(
            trainee_teacher: true
          )

          journey_session.save!
        end

        it { is_expected.to be_empty }
      end

      context "when not a trainee teacher" do
        it "includes all payment and result slugs" do
          is_expected.to match_array %w[
            personal-bank-account
            gender
            teacher-reference-number
            check-your-answers
            confirmation
          ]
        end
      end

      context "when teacher reference number is provided by Teacher ID" do
        before do
          journey_session.answers.assign_attributes(
            logged_in_with_tid: true,
            details_check: true,
            teacher_id_user_info: {
              "trn" => "1234567"
            }
          )

          journey_session.save!
        end

        it { is_expected.not_to include("teacher-reference-number") }
      end
    end
  end
end
