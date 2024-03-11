class EmploymentDetailsStep < BaseStep
  ROUTE_KEY = "employment-details".freeze

  REQUIRED_FIELDS = %i[
    school_name
    school_headteacher_name
    school_address_line_1
    school_city
    school_postcode
  ].freeze

  OPTIONAL_FIELDS = %i[school_address_line_2].freeze

  validates :school_postcode, postcode: true

  def configure_step
    @question = t("steps.employment_details.question")
    @question_type = :multi
  end

  def template
    "step/employment_details"
  end
end
