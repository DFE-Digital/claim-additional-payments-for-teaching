require "rails_helper"

RSpec.feature "GOVUK Nofity SMS sends OTP" do
  let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }

  context "when claimant opts to provide a mobile number" do
    let(:mobile_number) { "07123456789" }
    let(:otp_code) { rand(100_000..999_999).to_s }

    before do

      allow(NotifySmsMessage).to receive(:new).with(
        phone_number: mobile_number,
        template_id: NotifySmsMessage::OTP_PROMPT_TEMPLATE_ID,
        personalisation: {
          otp: otp_code
        }
      ).and_return(notify)
      allow(OneTimePassword::Generator).to receive(:new).and_return(instance_double("OneTimePassword::Generator", code: otp_code))
      allow(OneTimePassword::Validator).to receive(:new).and_return(instance_double("OneTimePassword::Validator", valid?: true))
    end

    context "when Policies::TargetedRetentionIncentivePayments" do
      let(:policy) { Policies::TargetedRetentionIncentivePayments }

      before do
        FeatureFlag.enable!(:tri_only_journey)

        create(:journey_configuration, :targeted_retention_incentive_payments_only)
      end

      scenario "makes claim" do
        send(:"start_#{policy.to_s.underscore}_claim")
        session = Journeys::TargetedRetentionIncentivePayments::Session.last

        session.update!(
          answers: attributes_for(
            :targeted_retention_incentive_payments_answers,
            :submittable,
            provide_mobile_number: true
          )
        )

        jump_to_claim_journey_page(
          slug: "mobile-number",
          journey_session: session
        )
        expect(session.reload.answers.provide_mobile_number).to eql true

        # - Mobile number
        expect(page).to have_text(I18n.t("questions.mobile_number"))
        fill_in "Mobile number", with: mobile_number
        click_on "Continue"

        expect(session.reload.answers.mobile_number).to eql(mobile_number)

        # # - Mobile number one-time password
        expect(page).to have_text("Mobile number verification")
        expect(page).to have_text("Enter the 6-digit passcode")
        fill_in "claim-one-time-password-field", with: otp_code
        click_on "Confirm"

        expect(page).to have_text("Enter your personal bank account details")
      end
    end

    context "when Policies::StudentLoans" do
      let(:policy) { Policies::StudentLoans }
      let(:school) { create(:school, :student_loans_eligible) }

      before do
        create(:journey_configuration, :student_loans)
      end

      scenario "when making a Policies::StudentLoans claim" do
        send(:"start_#{policy.to_s.underscore}_claim")
        session = Journeys::TeacherStudentLoanReimbursement::Session.last
        session
          .answers
          .assign_attributes(
            attributes_for(
              :student_loans_answers,
              :submittable
            )
          )
        session.save!

        jump_to_claim_journey_page(
          slug: "mobile-number",
          journey_session: session
        )
        expect(session.reload.answers.provide_mobile_number).to eql true

        # - Mobile number
        expect(page).to have_text(I18n.t("questions.mobile_number"))
        fill_in "Mobile number", with: mobile_number
        click_on "Continue"

        expect(session.reload.answers.mobile_number).to eql(mobile_number)

        # # - Mobile number one-time password
        expect(page).to have_text("Mobile number verification")
        expect(page).to have_text("Enter the 6-digit passcode")

        fill_in "claim-one-time-password-field", with: otp_code
        click_on "Confirm"

        expect(page).to have_text("Enter your personal bank account details")
      end
    end
  end
end
