# frozen_string_literal: true

module StudentLoans
  class Eligibility < ApplicationRecord
    SUBJECT_ATTRIBUTES = [
      :biology_taught,
      :chemistry_taught,
      :physics_taught,
      :computer_science_taught,
      :languages_taught,
    ].freeze

    self.table_name = "student_loans_eligibilities"

    enum qts_award_year: {
      "before_2013": 0,
      "2013_2014": 1,
      "2014_2015": 2,
      "2015_2016": 3,
      "2016_2017": 4,
      "2017_2018": 5,
      "2018_2019": 6,
      "2019_2020": 7,
    }, _prefix: :awarded_qualified_status

    enum employment_status: {
      claim_school: 0,
      different_school: 1,
      no_school: 2,
    }, _prefix: :employed_at

    belongs_to :claim_school, optional: true, class_name: "School"
    belongs_to :current_school, optional: true, class_name: "School"

    validates :qts_award_year, on: [:"qts-year", :submit], presence: {message: "Select the academic year you were awarded qualified teacher status"}
    validates :claim_school, on: [:"claim-school", :submit], presence: {message: "Select a school from the list"}
    validates :employment_status, on: [:"still-teaching", :submit], presence: {message: "Choose the option that describes your current employment status"}
    validates :current_school, on: [:"current-school", :submit], presence: {message: "Select a school from the list"}
    validate :one_subject_must_be_selected, on: [:"subjects-taught", :submit], unless: :not_taught_eligible_subjects_enough?
    validates :mostly_teaching_eligible_subjects, on: [:"mostly-teaching-eligible-subjects", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}

    delegate :name, to: :claim_school, prefix: true, allow_nil: true
    delegate :name, to: :current_school, prefix: true, allow_nil: true

    def subjects_taught
      SUBJECT_ATTRIBUTES.select { |attribute_name| public_send("#{attribute_name}?") }
    end

    def ineligible?
      ineligible_qts_award_year? || ineligible_claim_school? || employed_at_no_school? || not_taught_eligible_subjects_enough?
    end

    def ineligibility_reason
      [
        :ineligible_qts_award_year,
        :ineligible_claim_school,
        :employed_at_no_school,
        :not_taught_eligible_subjects_enough,
      ].find { |eligibility_check| send("#{eligibility_check}?") }
    end

    private

    def ineligible_qts_award_year?
      awarded_qualified_status_before_2013?
    end

    def ineligible_claim_school?
      claim_school.present? && !claim_school.eligible_for_tslr?
    end

    def not_taught_eligible_subjects_enough?
      mostly_teaching_eligible_subjects == false
    end

    def one_subject_must_be_selected
      errors.add(:subjects_taught, "Choose a subject, or select “not applicable”") if subjects_taught.empty?
    end
  end
end
