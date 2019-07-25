class School < ApplicationRecord
  SEARCH_RESULTS_LIMIT = 50
  SEARCH_NOT_ENOUGH_CHARACTERS_ERROR = "search_term must have a minimum of 4 characters".freeze

  belongs_to :local_authority
  belongs_to :local_authority_district

  validates :urn, presence: true
  validates :name, presence: true
  validates :phase, presence: true
  validates :school_type_group, presence: true
  validates :school_type, presence: true

  PHASES = {
    not_applicable: 0,
    nursery: 1,
    primary: 2,
    middle_deemed_primary: 3,
    secondary: 4,
    middle_deemed_secondary: 5,
    sixteen_plus: 6,
    all_through: 7,
  }.freeze

  SCHOOL_TYPE_GROUPS = {
    colleges: 1,
    universities: 2,
    independent_schools: 3,
    la_maintained: 4,
    special_schools: 5,
    welsh_schools: 6,
    other: 9,
    academies: 10,
    free_schools: 11,
  }.freeze

  STATE_FUNDED_SCHOOL_TYPE_GROUPS = %w[
    colleges
    la_maintained
    special_schools
    academies
    free_schools
  ].freeze

  SCHOOL_TYPES = {
    community_school: 1,
    voluntary_aided_school: 2,
    voluntary_controlled_school: 3,
    foundation_school: 5,
    city_technology_college: 6,
    community_special_school: 7,
    non_maintained_special_school: 8,
    other_independent_special_school: 10,
    other_independent_school: 11,
    foundation_special_school: 12,
    pupil_referral_unit: 14,
    local_authority_nursery_school: 15,
    further_education: 18,
    secure_unit: 24,
    offshore_school: 25,
    service_childrens_education: 26,
    miscellaneous: 27,
    academy_sponsor_led: 28,
    higher_education_institution: 29,
    welsh_establishment: 30,
    sixth_form_centre: 31,
    special_post_16_institutions: 32,
    academy_special_sponsor_led: 33,
    academy_converter: 34,
    free_school: 35,
    free_school_special: 36,
    british_school_oversea: 37,
    free_school_alternative_provider: 38,
    free_school_16_to_19: 39,
    university_technical_college: 40,
    studio_school: 41,
    academy_alternative_provision_converter: 42,
    academy_alternative_provision_sponsor_led: 43,
    academy_special_converter: 44,
    academy_16_to_19_converter: 45,
    academy_16_to_19_sponsor_led: 46,
    institution_funded_by_other_government_department: 56,
  }.freeze

  SPECIAL_SCHOOL_TYPES = %w[
    community_special_school
    non_maintained_special_school
    other_independent_special_school
    foundation_special_school
    special_post_16_institutions
    academy_special_sponsor_led
    free_school_special
    academy_special_converter
  ].freeze

  enum phase: PHASES
  enum school_type_group: SCHOOL_TYPE_GROUPS
  enum school_type: SCHOOL_TYPES

  def self.search(search_term)
    raise ArgumentError, SEARCH_NOT_ENOUGH_CHARACTERS_ERROR if search_term.length < 4

    where("name ILIKE ?", "%#{sanitize_sql_like(search_term)}%").limit(SEARCH_RESULTS_LIMIT)
  end

  def address
    [street, locality, town, county, postcode].reject(&:blank?).join(", ")
  end

  def eligible_for_tslr?
    StudentLoans::SchoolEligibility.new(self).check
  end

  def eligible_for_maths_and_physics?
    MathsAndPhysics::SchoolEligibility.new(self).check
  end

  def state_funded?
    STATE_FUNDED_SCHOOL_TYPE_GROUPS.include?(school_type_group) && school_type != "other_independent_special_school"
  end

  def special?
    SPECIAL_SCHOOL_TYPES.include?(school_type)
  end
end
