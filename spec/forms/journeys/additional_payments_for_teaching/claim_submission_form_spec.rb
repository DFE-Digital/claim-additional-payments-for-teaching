require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::ClaimSubmissionForm do
  before do
    create(:journey_configuration, :additional_payments)
  end

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:school) do
    create(
      :school,
      :early_career_payments_eligible,
      :levelling_up_premium_payments_eligible
    )
  end

  let(:claim_answers) do
    {
      address_line_1: "330",
      address_line_2: "Pikeland Ave",
      address_line_3: "Springfield",
      address_line_4: "Oregon",
      postcode: "TE57 1NG",
      date_of_birth: "1944-07-12",
      teacher_reference_number: "1234567",
      national_insurance_number: "AB123456C",
      email_address: "seymour-skinner@springfield-elementy.edu",
      bank_sort_code: "12-34-56",
      bank_account_number: "12345678",
      details_check: true,
      payroll_gender: "male",
      first_name: "Seymour",
      middle_name: "Walter",
      surname: "Skinner",
      banking_name: "Seymour W Skinner",
      building_society_roll_number: "12345678",
      academic_year: journey.configuration.current_academic_year.to_s,
      bank_or_building_society: "personal_bank_account",
      provide_mobile_number: true,
      mobile_number: "07123456789",
      email_verified: true,
      mobile_verified: true,
      hmrc_bank_validation_succeeded: true,
      hmrc_bank_validation_responses: {},
      logged_in_with_tid: true,
      teacher_id_user_info: {
        given_name: "Seymour",
        family_name: "Skinner",
        trn: "1234567",
        birthdate: "1944-07-12",
        ni_number: "AB123456C",
        trn_match_ni_number: "True",
        email: "seymour-skinner@springfield-elementy.edu"
      },
      email_address_check: true,
      mobile_check: "use",
      qualifications_details_check: true
    }
  end

  let(:eligibility_answers) do
    {
      nqt_in_academic_year_after_itt: true,
      employed_as_supply_teacher: false,
      qualification: "postgraduate_itt",
      has_entire_term_contract: nil,
      employed_directly: nil,
      subject_to_disciplinary_action: false,
      subject_to_formal_performance_action: false,
      eligible_itt_subject: "mathematics",
      eligible_degree_subject: "mathematics",
      teaching_subject_now: true,
      itt_academic_year: (journey.configuration.current_academic_year - 3).to_s,
      current_school_id: school.id,
      induction_completed: true,
      school_somewhere_else: nil
    }
  end

  let(:journey_session) do
    create(
      :additional_payments_session,
      journey: journey::ROUTING_NAME,
      answers: answers
    )
  end

  let(:form) { described_class.new(journey_session: journey_session) }

  describe "validations" do
    subject { form }

    before { form.valid? }

    describe "email_address" do
      context "when the email address is missing" do
        let(:answers) do
          {
            email_address: nil
          }
        end

        it "is not valid" do
          expect(form.errors[:email_address]).to include(
            "Enter an email address"
          )
        end
      end

      context "when the email address is present" do
        context "when the email address is unverified" do
          let(:answers) do
            {
              email_address: "seymour-skinner@springfield-elementy.edu",
              email_verified: nil
            }
          end

          it "is not valid" do
            expect(form.errors[:email_verified]).to include(
              "You must verify your email address before you can submit your claim"
            )
          end
        end
      end
    end

    describe "mobile_number" do
      context "when the teacher has choosen to provide their mobile number" do
        context "when the claim's mobile number is not from tid" do
          context "when the claim has an unverified mobile number" do
            let(:answers) do
              {
                mobile_check: "alternative",
                mobile_verified: nil,
                provide_mobile_number: true
              }
            end

            it "is not submitable" do
              expect(form.errors[:base]).to include(
                "You must verify your mobile number before you can submit your claim"
              )
            end
          end
        end
      end
    end

    describe "claim eligibility" do
      let(:answers) do
        claim_answers.merge(eligibility_answers).merge(
          nqt_in_academic_year_after_itt: false
        )
      end

      it "is not submitable" do
        expect(form.errors[:base]).to include(
          "You’re not eligible for this payment"
        )
      end
    end

    describe "not_already_submitted" do
      context "when the claim has already been submitted" do
        let(:answers) { {} }

        before do
          build(:claim, journey_session: journey_session)
          form.valid?
        end

        it "is not valid" do
          expect(form.errors[:base]).to include(
            "You have already submitted this claim"
          )
        end
      end
    end
  end

  describe "save" do
    let(:answers) { claim_answers.merge(eligibility_answers) }

    around do |example|
      travel_to(DateTime.new(2024, 3, 1, 9, 0, 0)) do
        example.run
      end
    end

    before do
      mailer_double = double(deliver_later: true)
      allow(ClaimMailer).to receive(:submitted).and_return(mailer_double)
      allow(ClaimVerifierJob).to receive(:perform_later)

      form.save
    end

    context "when a policy is not selected" do
      it "submits the claim for the default policy" do
        claim = form.claim

        expect(claim).to be_persisted

        expect(claim.policy_options_provided).to eq(
          [
            {
              "award_amount" => "2000.0",
              "policy" => "EarlyCareerPayments"
            },
            {
              "award_amount" => "2000.0",
              "policy" => "LevellingUpPremiumPayments"
            }
          ]
        )

        expect(claim.reference).to match(/([A-HJ-NP-Z]|\d){8}/)
        expect(claim.submitted_at).to eq DateTime.new(2024, 3, 1, 9, 0, 0)

        expect(claim.eligibility_type).to(
          eq("Policies::EarlyCareerPayments::Eligibility")
        )

        expect(journey_session.claim).to eq(claim)

        expect(ClaimMailer).to have_received(:submitted).with(claim)
        expect(ClaimVerifierJob).to have_received(:perform_later).with(claim)
      end
    end

    context "when a policy is selected" do
      let(:answers) do
        claim_answers.merge(
          eligibility_answers.merge(
            selected_policy: "LevellingUpPremiumPayments"
          )
        )
      end

      it "submits the claim for the selected policy" do
        claim = form.claim

        expect(claim).to be_persisted

        expect(claim.policy_options_provided).to eq(
          [
            {
              "award_amount" => "2000.0",
              "policy" => "EarlyCareerPayments"
            },
            {
              "award_amount" => "2000.0",
              "policy" => "LevellingUpPremiumPayments"
            }
          ]
        )

        expect(claim.reference).to match(/([A-HJ-NP-Z]|\d){8}/)
        expect(claim.submitted_at).to eq DateTime.new(2024, 3, 1, 9, 0, 0)

        expect(claim.eligibility_type).to(
          eq("Policies::LevellingUpPremiumPayments::Eligibility")
        )

        expect(journey_session.claim).to eq(claim)

        expect(claim.started_at).to eq(journey_session.created_at)

        expect(ClaimMailer).to have_received(:submitted).with(claim)
        expect(ClaimVerifierJob).to have_received(:perform_later).with(claim)
      end
    end
  end
end
