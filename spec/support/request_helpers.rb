module RequestHelpers
  def start_student_loans_claim
    start_claim(StudentLoans.routing_name)
  end

  def start_claim(routing_name)
    post claims_path(routing_name)
  end

  def non_service_operator_roles
    [
      DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE,
      DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE
    ]
  end

  # Signs in as a user with the service operator role. Returns the signed-in User record.
  def sign_in_as_service_operator
    user = create(:dfe_signin_user)
    sign_in_to_admin_with_role(DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, user.dfe_sign_in_id)
    user.reload
  end

  def sign_in_to_admin_with_role(*)
    stub_dfe_sign_in_with_role(*)
    post admin_dfe_sign_in_path
    follow_redirect!
  end

  def set_slug_sequence_in_session(claim, slug)
    current_claim = CurrentClaim.new(claims: [claim])
    slug_sequence = claim.policy::SlugSequence.new(current_claim).slugs
    slug_index = slug_sequence.index(slug)
    visited_slugs = slug_sequence.slice(0, slug_index)

    set_session_data(slugs: visited_slugs)
  end

  def set_session_data(data)
    put ::RackSessionAccess.path, params: {data: ::RackSessionAccess.encode(data)}
  end
end
