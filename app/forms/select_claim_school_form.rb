class SelectClaimSchoolForm
  def self.extract_params(claim_params, change_school:)
    new(claim_params, change_school).extract_params
  end

  def initialize(claim_params, change_school)
    @updated_claim_params = claim_params
    @change_school = change_school
  end

  def extract_params
    if @change_school == "true"
      ineligible_school_choose_change_school
    elsif @updated_claim_params.dig(:eligibility_attributes, :claim_school_id) == "somewhere_else"
      choose_somewhere_else
    elsif @updated_claim_params[:eligibility_attributes]
      selected_suggested_school
    end

    @updated_claim_params
  end

  private

  def ineligible_school_choose_change_school
    @updated_claim_params[:eligibility_attributes] = {claim_school_id: nil, claim_school_somewhere_else: true}
  end

  def choose_somewhere_else
    # This removes "somewhere_else" passed in as the claim_school_id
    @updated_claim_params[:eligibility_attributes][:claim_school_id] = nil
    @updated_claim_params[:eligibility_attributes][:claim_school_somewhere_else] = true
  end

  def selected_suggested_school
    @updated_claim_params[:eligibility_attributes][:claim_school_somewhere_else] = false
  end
end
