module EarlyCareerPayments
  class Eligibility < ApplicationRecord
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
      :postgraduate_masters_loan,
      :postgraduate_doctoral_loan
    ].freeze
    AMENDABLE_ATTRIBUTES = [].freeze
    ATTRIBUTE_DEPENDENCIES = {
      "employed_as_supply_teacher" => ["has_entire_term_contract", "employed_directly"],
      "qualification" => ["eligible_itt_subject", "teaching_subject_now"],
      "eligible_itt_subject" => ["teaching_subject_now"],
      "has_student_loan" => ["postgraduate_masters_loan", "postgraduate_doctoral_loan"]
    }.freeze

    self.table_name = "early_career_payments_eligibilities"

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
      "2018_2019": 0,
      "2019_2020": 1,
      "2020_2021": 2,
      none_of_the_above: 3
    }, _prefix: :itt_academic_year

    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :current_school, optional: true, class_name: "School"

    validates :nqt_in_academic_year_after_itt, on: [:"nqt-in-academic-year-after-itt", :submit], inclusion: {in: [true, false], message: "Select yes if you did your NQT in the academic year after your ITT"}
    validates :current_school, on: [:"current-school", :submit], presence: {message: "Select a school from the list or search again for a different school"}
    validates :employed_as_supply_teacher, on: [:"supply-teacher", :submit], inclusion: {in: [true, false], message: "Select yes if you are currently employed as a supply teacher"}
    validates :has_entire_term_contract, on: [:"entire-term-contract", :submit], inclusion: {in: [true, false], message: "Select yes if you have a contract to teach at the same school for one term or longer"}, if: :employed_as_supply_teacher?
    validates :employed_directly, on: [:"employed-directly", :submit], inclusion: {in: [true, false], message: "Select yes if you are employed directly by your school"}, if: :employed_as_supply_teacher?
    validates :subject_to_formal_performance_action, on: [:"poor-performance", :submit], inclusion: {in: [true, false], message: "Select yes if you are subject to formal action for poor performance at work"}
    validates :subject_to_disciplinary_action, on: [:"poor-performance", :submit], inclusion: {in: [true, false], message: "Select yes if you are subject to disciplinary action"}
    validates :qualification, on: [:qualification, :submit], presence: {message: "Select which route into teaching you took"}
    validates :eligible_itt_subject, on: [:"eligible-itt-subject", :submit], presence: {message: "Select if you completed your initial teacher training in Chemistry, Foreign Languages, Mathematics, Physics or None of these subjects"}
    validates :teaching_subject_now, on: [:"teaching-subject-now", :submit], inclusion: {in: [true, false], message: "Select yes if you are currently teaching in your ITT subject now"}
    validates :itt_academic_year, on: [:"itt-year", :submit], presence: {message: ->(object, data) { I18n.t("activerecord.errors.models.early_career_payments_eligibilities.attributes.itt_academic_year.blank.qualification.#{object.qualification}") }}
    validates :postgraduate_masters_loan, on: [:"masters-loan", :submit], inclusion: {in: [true, false], message: "Select yes if you have a Postgraduate Master Loan taken out on or after 1st August 2016"}, unless: :no_student_loan?
    validates :postgraduate_doctoral_loan, on: [:"doctoral-loan", :submit], inclusion: {in: [true, false], message: "Select yes if you have a Postgraduate Doctoral Loan taken out on or after 1st August 2018"}, unless: :no_student_loan?

    delegate :name, to: :current_school, prefix: true, allow_nil: true

    def policy
      EarlyCareerPayments
    end

    def qualification_name
      return qualification.gsub("_itt", " ITT") if qualification.split("_").last == "itt"

      qualification_attained = qualification.humanize.downcase

      qualification_attained == "assessment only" ? qualification_attained : qualification_attained + " qualification"
    end

    def eligible_later?
      eligible_later_cohort = find_cohort(
        cohorts: {
          mathematics: [
            "2019_2020",
            "2020_2021"
          ],
          chemistry: [
            "2020_2021"
          ],
          physics: [
            "2020_2021"
          ],
          foreign_languages: [
            "2020_2021"
          ]
        }
      )

      eligible_later_cohort.nil? ? false : true
    end

    # This doesn't mean it's eligible either, ie, eligibility could be undetermined
    def ineligible?
      ineligible_nqt_in_academic_year_after_itt? ||
        ineligible_current_school? ||
        no_entire_term_contract? ||
        not_employed_directly? ||
        poor_performance? ||
        itt_subject_none_of_the_above? ||
        not_teaching_now_in_eligible_itt_subject? ||
        ineligible_cohort?
    end

    def ineligibility_reason
      [
        :generic_ineligibility,
        :ineligible_current_school,
        :poor_performance,
        :itt_subject_none_of_the_above,
        :not_teaching_now_in_eligible_itt_subject,
        :ineligible_nqt_in_academic_year_after_itt
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    def award_amount
      return BigDecimal("0.00") if current_school.nil?

      current_school.eligible_for_early_career_payments_as_uplift? ? award_amounts[:uplift] : award_amounts[:base]
    end

    def award_amounts
      if without_cohort?
        return {
          base: BigDecimal("0.00"),
          uplift: BigDecimal("0.00")
        }
      end

      award_amounts = {
        mathematics: {
          "2018_2019": {
            base: BigDecimal("5000.00"),
            uplift: BigDecimal("7500.00")
          },
          "2019_2020": {
            base: BigDecimal("5000.00"),
            uplift: BigDecimal("7500.00")
          },
          "2020_2021": {
            base: BigDecimal("2000.00"),
            uplift: BigDecimal("3000.00")
          }
        },
        chemistry: {
          "2020_2021": {
            base: BigDecimal("2000.00"),
            uplift: BigDecimal("3000.00")
          }
        },
        physics: {
          "2020_2021": {
            base: BigDecimal("2000.00"),
            uplift: BigDecimal("3000.00")
          }
        },
        foreign_languages: {
          "2020_2021": {
            base: BigDecimal("2000.00"),
            uplift: BigDecimal("3000.00")
          }
        }
      }.dig(eligible_itt_subject.to_sym, itt_academic_year.to_sym)

      if award_amounts.nil?
        return {
          base: BigDecimal("0.00"),
          uplift: BigDecimal("0.00")
        }
      end

      award_amounts
    end

    def reset_dependent_answers
      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if changed.include?(attribute_name) || claim.changed.include?(attribute_name)
        end
      end
    end

    private

    def find_cohort(cohorts:)
      cohorts.find do |cohort_itt_subject, cohort_itt_academic_years|
        cohort_itt_subject.to_s == eligible_itt_subject && cohort_itt_academic_years.any?(itt_academic_year)
      end
    end

    def without_cohort?
      [eligible_itt_subject, itt_academic_year].any?(nil)
    end

    def ineligible_cohort?
      return true if itt_academic_year == "none_of_the_above"
      return false if without_cohort?

      eligible_cohort = find_cohort(
        cohorts: {
          mathematics: [
            "2018_2019",
            "2019_2020",
            "2020_2021"
          ],
          chemistry: [
            "2020_2021"
          ],
          physics: [
            "2020_2021"
          ],
          foreign_languages: [
            "2020_2021"
          ]
        }
      )

      eligible_cohort.nil? ? true : false
    end

    def ineligible_nqt_in_academic_year_after_itt?
      nqt_in_academic_year_after_itt == false
    end

    def ineligible_current_school?
      current_school.present? && !current_school.eligible_for_early_career_payments?
    end

    def no_entire_term_contract?
      employed_as_supply_teacher? && has_entire_term_contract == false
    end

    def not_employed_directly?
      employed_as_supply_teacher? && employed_directly == false
    end

    def not_teaching_now_in_eligible_itt_subject?
      teaching_subject_now == false
    end

    def poor_performance?
      subject_to_formal_performance_action? ||
        subject_to_disciplinary_action?
    end

    def generic_ineligibility?
      no_entire_term_contract? ||
        not_employed_directly? ||
        ineligible_cohort?
    end

    def no_student_loan?
      claim.no_student_loan?
    end
  end
end
