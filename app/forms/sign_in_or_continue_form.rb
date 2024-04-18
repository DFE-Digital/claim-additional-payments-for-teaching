class SignInOrContinueForm < Form
  # - Sign in with Teacher ID does NOT save or interact with this Form and POSTs straight to Teacher ID
  # - If Teacher ID is disabled for the journey, we still mimick if a user clicked on "Continue without signing in".

  def initialize(claim:, journey:, params:)
    super

    skip_form_if_teacher_id_not_enabled_for_journey
  end

  def save
    continue_without_teacher_id

    true
  end

  # This is needed because logging in with Teacher ID doesn't submit to this form.
  # Therefore the slug/page needs to be considered submitted to avoid it being the next slug
  # after callback redirect back to Claim from Teacher ID.
  def force_update_session_with_current_slug
    true
  end

  private

  def skip_form_if_teacher_id_not_enabled_for_journey
    if !journey.configuration.teacher_id_enabled?
      update_claim_with_teacher_id_was_skipped
      @redirect_to_next_slug = true
    end
  end

  def continue_without_teacher_id
    update_claim_with_teacher_id_was_skipped
  end

  def update_claim_with_teacher_id_was_skipped
    # This reset is called from multiple places.
    # The smell here is we are updating the claim on initialisation when teacher id is disabled.
    # Leaving this here for now, until/if we decide to address approach.
    DfeIdentity::ClaimUserDetailsReset.call(claim, :skipped_tid)
  end
end
