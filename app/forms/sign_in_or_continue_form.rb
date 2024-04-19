class SignInOrContinueForm < Form
  # - Sign in with Teacher ID does NOT save or interact with this Form and POSTs straight to Teacher ID
  # - If Teacher ID is disabled for the journey, we still mimick if a user clicked on "Continue without signing in".

  def initialize(claim:, journey:, params:)
    super
  end

  def save
    # This reset is called from multiple places.
    # The smell here is we are updating the claim on initialisation when teacher id is disabled.
    # Leaving this here for now, until/if we decide to address approach.
    DfeIdentity::ClaimUserDetailsReset.call(claim, :skipped_tid)

    true
  end
end
