class StillTeachingForm
  def self.extract_params(claim_params)
    new(claim_params).extract_params
  end

  def initialize(claim_params)
    @updated_claim_params = claim_params
  end

  def extract_params
    # current_school_id is in a hidden field, we only want this if the teacher selected the suggested school playback
    unless %w[claim_school recent_tps_school].include?(@updated_claim_params.dig(:eligibility_attributes, :employment_status))
      @updated_claim_params[:eligibility_attributes][:current_school_id] = nil
    end

    @updated_claim_params
  end
end
