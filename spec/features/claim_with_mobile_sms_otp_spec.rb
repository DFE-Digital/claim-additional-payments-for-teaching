require "rails_helper"

RSpec.feature "GOVUK Nofity SMS sends OTP" do
  let(:notify) { instance_double("NotifySmsMessage", deliver!: true) }

  [
    {policy: Policies::EarlyCareerPayments, mobile_number: "07123456789", otp_code: "097543"},
    {policy: Policies::StudentLoans, mobile_number: "07723190022", otp_code: "123347"}
  ].each do |scenario|
    context "when claimant opts to provide a mobile number" do
      before do
        create(:journey_configuration, scenario[:policy].to_s.underscore)

        allow(NotifySmsMessage).to receive(:new).with(
          phone_number: mobile_number,
          template_id: NotifySmsMessage::OTP_PROMPT_TEMPLATE_ID,
          personalisation: {
            otp: scenario[:otp_code]
          }
        ).and_return(notify)
        allow(OneTimePassword::Generator).to receive(:new).and_return(instance_double("OneTimePassword::Generator", code: scenario[:otp_code]))
        allow(OneTimePassword::Validator).to receive(:new).and_return(instance_double("OneTimePassword::Validator", valid?: true))
      end
      let(:mobile_number) { scenario[:mobile_number] }

      scenario "when making a #{scenario[:policy]} claim" do
        send(:"start_#{scenario[:policy].to_s.underscore}_claim")
        if scenario[:policy] == Policies::EarlyCareerPayments
          session = Journeys::AdditionalPaymentsForTeaching::Session.last
        elsif scenario[:policy] == Policies::StudentLoans
          session = Journeys::TeacherStudentLoanReimbursement::Session.last
        end

        session.update!(answers: {provide_mobile_number: true})

        jump_to_claim_journey_page(
          slug: "mobile-number",
          journey_session: session
        )
        expect(session.reload.answers.provide_mobile_number).to eql true

        # - Mobile number
        expect(page).to have_text(I18n.t("questions.mobile_number"))

        fill_in "Mobile number", with: scenario[:mobile_number]
        click_on "Continue"

        expect(session.reload.answers.mobile_number).to eql(scenario[:mobile_number])

        # # - Mobile number one-time password
        expect(page).to have_text("Mobile number verification")
        expect(page).to have_text("Enter the 6-digit passcode")

        fill_in "claim_one_time_password", with: scenario[:otp_code]
        click_on "Confirm"

        expect(page).to have_text(I18n.t("questions.bank_or_building_society"))
      end
    end
  end
end
