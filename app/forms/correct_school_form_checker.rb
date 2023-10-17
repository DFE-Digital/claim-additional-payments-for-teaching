class CorrectSchoolFormChecker
  def self.call(claim_params, change_school:)
    new(claim_params, change_school).check_correct_school_params
  end

  def initialize(claim_params, change_school)
    @updated_claim_params = claim_params
    @change_school = change_school
  end

  def check_correct_school_params
    if @change_school == "true"
      ineligible_school_choose_change_school
    elsif @updated_claim_params.dig(:eligibility_attributes, :current_school_id) == "somewhere_else"
      choose_somewhere_else
    elsif @updated_claim_params[:eligibility_attributes]
      selected_suggested_school
    end
  end

  # User was suggested a school, but turns out the school is ineligible.
  # `Change school` button clears the `current_school_id`` and set `school_somewhere_else` to true.
  # So the user can select a different school than the one suggested.
  def ineligible_school_choose_change_school
    @updated_claim_params[:eligibility_attributes] = {current_school_id: nil, school_somewhere_else: true}
  end

  def choose_somewhere_else
    # This removes "somewhere_else" passed in as the current_school_id
    @updated_claim_params[:eligibility_attributes].delete(:current_school_id)

    @updated_claim_params[:eligibility_attributes][:school_somewhere_else] = true
  end

  def selected_suggested_school
    @updated_claim_params[:eligibility_attributes][:school_somewhere_else] = false
  end
end
