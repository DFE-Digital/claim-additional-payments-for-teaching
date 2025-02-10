class ClaimMailerPreview < ActionMailer::Preview
  def submitted_ecp
    ClaimMailer.submitted(claim_for(Claim.submitted.by_policy(Policies::EarlyCareerPayments)))
  end

  def submitted_lup
    ClaimMailer.submitted(claim_for(Claim.submitted.by_policy(Policies::LevellingUpPremiumPayments)))
  end

  def approved_ecp
    ClaimMailer.approved(claim_for(Claim.approved.by_policy(Policies::EarlyCareerPayments)))
  end

  def approved_lup
    ClaimMailer.approved(claim_for(Claim.approved.by_policy(Policies::LevellingUpPremiumPayments)))
  end

  def rejected_ecp
    ClaimMailer.rejected(claim_for(Claim.rejected.by_policy(Policies::EarlyCareerPayments)))
  end

  def rejected_lup
    ClaimMailer.rejected(claim_for(Claim.rejected.by_policy(Policies::LevellingUpPremiumPayments)))
  end

  def update_after_three_weeks_ecp
    ClaimMailer.update_after_three_weeks(claim_for(Claim.approved.by_policy(Policies::EarlyCareerPayments)))
  end

  def update_after_three_weeks_lup
    ClaimMailer.update_after_three_weeks(claim_for(Claim.approved.by_policy(Policies::LevellingUpPremiumPayments)))
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
