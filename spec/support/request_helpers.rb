module RequestHelpers
  def start_student_loans_claim
    start_claim(StudentLoans)
  end

  def start_claim(policy)
    post claims_path(policy.routing_name), params: {claim: claim_create_params_for(policy)}
  end

  def claim_create_params_for(policy)
    {
      StudentLoans => {
        eligibility_attributes: {
          qts_award_year: "on_or_after_september_2013",
        },
      },
    }.fetch(policy)
  end

  def sign_in_to_admin_with_role(*args)
    stub_dfe_sign_in_with_role(*args)
    post admin_dfe_sign_in_path
    follow_redirect!
  end
end
