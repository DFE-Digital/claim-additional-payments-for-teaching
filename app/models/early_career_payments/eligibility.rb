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
      :itt_academic_year
    ].freeze
    AMENDABLE_ATTRIBUTES = [].freeze
    ATTRIBUTE_DEPENDENCIES = {
      "employed_as_supply_teacher" => ["has_entire_term_contract", "employed_directly"],
      "qualification" => ["eligible_itt_subject", "teaching_subject_now"],
      "eligible_itt_subject" => ["teaching_subject_now"]
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
      AcademicYear.new(2018) => AcademicYear::Type.new.serialize(AcademicYear.new(2018)),
      AcademicYear.new(2019) => AcademicYear::Type.new.serialize(AcademicYear.new(2019)),
      AcademicYear.new(2020) => AcademicYear::Type.new.serialize(AcademicYear.new(2020)),
      AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)
    }

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
    validates :eligible_itt_subject, on: [:"eligible-itt-subject", :submit], presence: {message: ->(object, data) { I18n.t("activerecord.errors.models.early_career_payments_eligibilities.attributes.eligible_itt_subject.blank.qualification.#{object.qualification}") }}
    validates :teaching_subject_now, on: [:"teaching-subject-now", :submit], inclusion: {in: [true, false], message: ->(object, data) { I18n.t("activerecord.errors.models.early_career_payments_eligibilities.attributes.teaching_subject_now.blank.subject.#{object.eligible_itt_subject}") }}
    validates :itt_academic_year, on: [:"itt-year", :submit], presence: {message: ->(object, data) { I18n.t("activerecord.errors.models.early_career_payments_eligibilities.attributes.itt_academic_year.blank.qualification.#{object.qualification}") }}

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
      find_cohort(
        cohorts: {
          mathematics: [
            AcademicYear.new(2019),
            AcademicYear.new(2020)
          ],
          chemistry: [
            AcademicYear.new(2020)
          ],
          physics: [
            AcademicYear.new(2020)
          ],
          foreign_languages: [
            AcademicYear.new(2020)
          ]
        }
      ).present?
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
          AcademicYear.new(2018) => {
            base: BigDecimal("5000.00"),
            uplift: BigDecimal("7500.00")
          },
          AcademicYear.new(2019) => {
            base: BigDecimal("5000.00"),
            uplift: BigDecimal("7500.00")
          },
          AcademicYear.new(2020) => {
            base: BigDecimal("2000.00"),
            uplift: BigDecimal("3000.00")
          }
        },
        chemistry: {
          AcademicYear.new(2020) => {
            base: BigDecimal("2000.00"),
            uplift: BigDecimal("3000.00")
          }
        },
        physics: {
          AcademicYear.new(2020) => {
            base: BigDecimal("2000.00"),
            uplift: BigDecimal("3000.00")
          }
        },
        foreign_languages: {
          AcademicYear.new(2020) => {
            base: BigDecimal("2000.00"),
            uplift: BigDecimal("3000.00")
          }
        }
      }.dig(eligible_itt_subject.to_sym, itt_academic_year)

      if award_amounts.nil?
        return {
          base: BigDecimal("0.00"),
          uplift: BigDecimal("0.00")
        }
      end

      award_amounts
    end

    AwardAmount = Struct.new(
      :itt_subject,
      :itt_academic_year,
      :claim_academic_year,
      :base_amount,
      :uplift_amount,
      keyword_init: true
    )

    def first_eligible_itt_academic_year
      award_amounts = [
        AwardAmount.new(
          itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2018),
          claim_academic_year: AcademicYear.new(2021),
          base_amount: 5_000,
          uplift_amount: 7_500
        ),
        AwardAmount.new(
          itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2019),
          claim_academic_year: AcademicYear.new(2022),
          base_amount: 5_000,
          uplift_amount: 7_500
        ),
        AwardAmount.new(
          itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2022),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :physics,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2022),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :chemistry,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2022),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :foreign_languages,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2022),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2018),
          claim_academic_year: AcademicYear.new(2023),
          base_amount: 5_000,
          uplift_amount: 7_500
        ),
        AwardAmount.new(
          itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2023),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :physics,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2023),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :chemistry,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2023),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :foreign_languages,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2023),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2019),
          claim_academic_year: AcademicYear.new(2024),
          base_amount: 5_000,
          uplift_amount: 7_500
        ),
        AwardAmount.new(
          itt_subject: :mathematics,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2024),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :physics,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2024),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :chemistry,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2024),
          base_amount: 2_000,
          uplift_amount: 3_000
        ),
        AwardAmount.new(
          itt_subject: :foreign_languages,
          itt_academic_year: AcademicYear.new(2020),
          claim_academic_year: AcademicYear.new(2024),
          base_amount: 2_000,
          uplift_amount: 3_000
        )
      ]

      award_amount = award_amounts.find do |award_amount|
        award_amount.claim_academic_year == claim.academic_year &&
          award_amount.itt_subject.to_s == eligible_itt_subject
      end

      award_amount&.itt_academic_year
    end

    def reset_dependent_answers
      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if changed.include?(attribute_name)
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
      return true if itt_academic_year == AcademicYear.new
      return false if without_cohort?

      find_cohort(
        cohorts: {
          mathematics: [
            AcademicYear.new(2018),
            AcademicYear.new(2019),
            AcademicYear.new(2020)
          ],
          chemistry: [
            AcademicYear.new(2020)
          ],
          physics: [
            AcademicYear.new(2020)
          ],
          foreign_languages: [
            AcademicYear.new(2020)
          ]
        }
      ).blank?
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
        poor_performance? ||
        ineligible_cohort?
    end

    def no_student_loan?
      claim.no_student_loan?
    end
  end
end
