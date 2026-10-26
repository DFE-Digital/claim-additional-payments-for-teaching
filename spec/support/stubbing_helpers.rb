module StubbingHelpers
  def disable_claim_qa_flagging
    Journeys::Configuration.update_all(
      approved_min_qa_threshold: 0,
      rejected_min_qa_threshold: 0
    )
  end

  def stub_otp_verification(otp_code: "123456", valid: true)
    allow_any_instance_of(NotifySmsMessage).to receive(:deliver!)
    allow_any_instance_of(OneTimePassword::Generator).to receive(:code).and_return(otp_code)
    allow_any_instance_of(OneTimePassword::Validator).to receive(:valid?).and_return(valid)
  end
end
