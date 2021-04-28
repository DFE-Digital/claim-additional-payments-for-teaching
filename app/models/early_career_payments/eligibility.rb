module EarlyCareerPayments
  class Eligibility < ApplicationRecord
    EDITABLE_ATTRIBUTES = [
      :nqt_in_academic_year_after_itt,
      #:school_search,
      :employed_as_supply_teacher,
      :has_entire_term_contract,
      :employed_directly,
      :subject_to_disciplinary_action,
      :pgitt_or_ugitt_course
    ].freeze
    AMENDABLE_ATTRIBUTES = [].freeze
    ATTRIBUTE_DEPENDENCIES = {
      "employed_as_supply_teacher" => ["has_entire_term_contract", "employed_directly"]
    }.freeze

    self.table_name = "early_career_payments_eligibilities"

    enum pgitt_or_ugitt_course: {
      postgraduate: 0,
      undergraduate: 1
    }, _suffix: :itt_course

    has_one :claim, as: :eligibility, inverse_of: :eligibility

    validates :nqt_in_academic_year_after_itt, on: [:"nqt-in-academic-year-after-itt", :submit], inclusion: {in: [true, false], message: "Select yes if you did your NQT in the academic year after your ITT"}
    #validates :school_search, on: [:"school_search", :submit], presence: {message: "Select a school from the list or search again for a different school"}
    validates :employed_as_supply_teacher, on: [:"supply-teacher", :submit], inclusion: {in: [true, false], message: "Select yes if you are currently employed as a supply teacher"}
    validates :has_entire_term_contract, on: [:"entire-term-contract", :submit], inclusion: {in: [true, false], message: "Select yes if you have a contract to teach at the same school for one term or longer"}, if: :employed_as_supply_teacher?
    validates :employed_directly, on: [:"employed-directly", :submit], inclusion: {in: [true, false], message: "Select yes if you are employed directly by your school"}, if: :employed_as_supply_teacher?
    validates :subject_to_disciplinary_action, on: [:"disciplinary-action", :submit], inclusion: {in: [true, false], message: "Select yes if you are subject to disciplinary action"}
    validates :pgitt_or_ugitt_course, on: [:"postgraduate-itt-or-undergraduate-itt-course", :submit], presence: {message: "Select postgraduate if you did a Postgraduate ITT course"}

    def policy
      EarlyCareerPayments
    end

    def ineligible?
      ineligible_nqt_in_academic_year_after_itt? ||
        no_entire_term_contract? ||
        not_employed_directly? ||
        subject_to_disciplinary_action?
    end

    def award_amount
      BigDecimal("2000.00")
    end

    def reset_dependent_answers
      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if changed.include?(attribute_name)
        end
      end
    end

    private

    def ineligible_nqt_in_academic_year_after_itt?
      nqt_in_academic_year_after_itt == false
    end

    def no_entire_term_contract?
      employed_as_supply_teacher? && has_entire_term_contract == false
    end

    def not_employed_directly?
      employed_as_supply_teacher? && employed_directly == false
    end
  end
end
