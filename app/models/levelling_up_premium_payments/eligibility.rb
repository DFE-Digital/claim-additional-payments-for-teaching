module LevellingUpPremiumPayments
  class Eligibility < ApplicationRecord
    self.table_name = "levelling_up_premium_payments_eligibilities"
    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :current_school, optional: true, class_name: "School"

    # use first year of LUP for now but this must come from a PolicyConfiguration
    validates :award_amount, on: :amendment, award_range: {max: LevellingUpPremiumPayments::Award.max(AcademicYear.new(2022))}

    EDITABLE_ATTRIBUTES = [
      :nqt_in_academic_year_after_itt,
      :current_school_id,
      :employed_as_supply_teacher,
      :has_entire_term_contract,
      :employed_directly,
      :subject_to_formal_performance_action,
      :subject_to_disciplinary_action,
      :qualification,
      :eligible_itt_subject,
      :teaching_subject_now,
      :itt_academic_year,
      :award_amount
    ].freeze
    AMENDABLE_ATTRIBUTES = [:award_amount].freeze
    ATTRIBUTE_DEPENDENCIES = {
      "employed_as_supply_teacher" => ["has_entire_term_contract", "employed_directly"],
      "qualification" => ["eligible_itt_subject", "teaching_subject_now"],
      "eligible_itt_subject" => ["teaching_subject_now"],
      "itt_academic_year" => ["eligible_itt_subject"]
    }.freeze

    enum qualification: {
      postgraduate_itt: 0,
      undergraduate_itt: 1,
      assessment_only: 2,
      overseas_recognition: 3
    }

    enum eligible_itt_subject: {
      chemistry: 0,
      foreign_languages: 1,
      mathematics: 2,
      physics: 3,
      none_of_the_above: 4
    }, _prefix: :itt_subject

    enum itt_academic_year: {
      AcademicYear.new(2018) => AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
      AcademicYear.new(2019) => AcademicYear::Type.new.serialize(AcademicYear.new(2019)),
      AcademicYear.new(2020) => AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
      AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)
    }

    def policy
      LevellingUpPremiumPayments
    end

    # maintains interface
    def ineligible?
    end

    # TODO - this need implementing later
    def reset_dependent_answers
    end
  end
end
