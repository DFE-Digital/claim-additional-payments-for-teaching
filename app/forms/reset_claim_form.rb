class ResetClaimForm < Form
  include ActiveModel::Model

  def reset_claim_trn_missing?
    !answers.details_check? && DfeIdentity::UserInfo.trn_missing?(
      answers.teacher_id_user_info
    )
  end

  def save
    true
  end
end
