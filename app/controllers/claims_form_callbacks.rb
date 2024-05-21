module ClaimsFormCallbacks
  def current_school_before_show
    set_backlink_override_to_current_slug if on_school_search_results?
  end

  def claim_school_before_show
    set_backlink_override_to_current_slug if on_school_search_results?
  end

  def teaching_subject_now_before_show
    redirect_to_slug("eligible-itt-subject") if no_eligible_itt_subject?
  end

  def qualification_details_before_show
    redirect_to_next_slug if no_dqt_data?
  end

  def address_before_show
    set_backlink_override(slug: "postcode-search") if no_postcode?
  end

  def select_home_address_before_show
    set_backlink_override(slug: "postcode-search")
  end

  private

  def set_backlink_override_to_current_slug
    set_backlink_override(slug: current_slug)
  end

  def set_backlink_override(slug:)
    @backlink_path = claim_path(current_journey_routing_name, slug) if page_sequence.in_sequence?(slug)
  end

  def on_school_search_results?
    params[:school_search]&.present?
  end

  def no_eligible_itt_subject?
    !current_claim.eligible_itt_subject
  end

  def no_dqt_data?
    current_claim.has_no_dqt_data_for_claim?
  end

  def no_postcode?
    !current_claim.postcode
  end
end
