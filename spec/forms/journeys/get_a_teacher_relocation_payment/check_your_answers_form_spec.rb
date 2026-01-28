require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::CheckYourAnswersForm do
  let(:journey_configuration) do
    create(:journey_configuration, :get_a_teacher_relocation_payment)
  end

  let(:claim_answers) do
    {
      address_line_1: "330",
      address_line_2: "Pikeland Ave",
      address_line_3: "Springfield",
      address_line_4: "Oregon",
      postcode: "TE57 1NG",
      date_of_birth: Date.new(1944, 7, 12),
      national_insurance_number: "AB123456C",
      email_address: "seymour-skinner@springfield-elementy.edu",
      bank_sort_code: "123456",
      bank_account_number: "12345678",
      details_check: true,
      payroll_gender: "male",
      first_name: "Seymour",
      middle_name: "Walter",
      surname: "Skinner",
      banking_name: "Seymour W Skinner",
      building_society_roll_number: "12345678",
      academic_year: journey_configuration.current_academic_year.to_s,
      bank_or_building_society: "personal_bank_account",
      provide_mobile_number: true,
      mobile_number: "07123456789",
      email_verified: true,
      mobile_verified: true,
      hmrc_bank_validation_succeeded: true,
      hmrc_bank_validation_responses: {}
    }
  end

  let(:start_date) { Date.tomorrow }

  let(:eligibility_answers) do
    {
      application_route: "teacher",
      state_funded_secondary_school: true,
      one_year: true,
      start_date: start_date,
      subject: "physics",
      visa_type: "British National (Overseas) visa",
      date_of_entry: start_date - 1.week,
      nationality: "Australian",
      passport_number: "1234567890123456789A",
      school_headteacher_name: "Seymour Skinner",
      current_school_id: create(:school).id
    }
  end

  let(:journey_session) do
    create(
      :get_a_teacher_relocation_payment_session,
      answers: answers
    )
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      session: {},
      params: ActionController::Parameters.new,
      journey: Journeys::GetATeacherRelocationPayment
    )
  end

  describe "#save" do
    let(:answers) do
      build(
        :get_a_teacher_relocation_payment_answers,
        **claim_answers.merge(eligibility_answers)
      )
    end

    subject { form.save }

    it "sets the expect attributes on the claim" do
      subject

      claim = form.claim

      eligibility = claim.eligibility

      claim_answers.each do |attribute, value|
        expect(claim.public_send(attribute)).to eq(value)
      end

      expect(claim.policy).to eql(Policies::InternationalRelocationPayments)

      expect(claim.submitted_at).to be_present
      expect(claim.reference).to be_present
      expect(claim.started_at).to eq(journey_session.created_at)

      eligibility_answers.each do |attribute, value|
        expect(eligibility.public_send(attribute)).to eq(value)
      end

      expect(eligibility.award_amount).to eq(
        Policies::InternationalRelocationPayments.award_amount
      )
    end

    it "create a claim_submitted Event" do
      expect { subject }.to(
        change { Event.where(name: "claim_submitted").count }.by(1)
      )
    end
  end
end
