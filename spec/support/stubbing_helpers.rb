module StubbingHelpers
  def disable_claim_qa_flagging
    stub_const("Claim::MIN_QA_THRESHOLD", 0)
  end
end
