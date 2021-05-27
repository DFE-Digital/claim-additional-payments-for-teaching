class ClaimMailerPreview < ActionMailer::Preview
  def submitted
    ClaimMailer.submitted(claim_for(Claim.submitted))
  end

  def approved
    ClaimMailer.approved(claim_for(Claim.approved))
  end

  def rejected
    ClaimMailer.rejected(claim_for(Claim.rejected))
  end

  def update_after_three_weeks
    ClaimMailer.update_after_three_weeks(claim_for(Claim.approved))
  end

  def ecp_email_verification
    ClaimMailer.ecp_email_verification(claim_for(Claim.unsubmitted), "@one_time_password")
  end

  private

  def claim_for(scope)
    scoped_by_policy(scope).order(:created_at).last
  end

  def scoped_by_policy(scope)
    if (policy = Policies[params[:policy]])
      scope.by_policy(policy)
    else
      scope
    end
  end
end
