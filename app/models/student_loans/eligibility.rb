# frozen_string_literal: true

module StudentLoans
  class Eligibility < ApplicationRecord
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

    has_many :employments
    accepts_nested_attributes_for :employments

    validates :qts_award_year, on: [:"qts-year", :submit], presence: {message: "Select the academic year you were awarded qualified teacher status"}
    validates :employment_status, on: [:"still-teaching", :submit], presence: {message: "Choose the option that describes your current employment status"}
    validates :current_school, on: [:"current-school", :submit], presence: {message: "Select a school from the list"}
    validates :had_leadership_position, on: [:"leadership-position", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}
    validates :mostly_performed_leadership_duties, on: [:"mostly-performed-leadership-duties", :submit], inclusion: {in: [true, false], message: "Select either Yes or No"}, if: :had_leadership_position?

    delegate :name, to: :current_school, prefix: true, allow_nil: true

    # Represents the claimant's employment that they are filling out details for
    # TODO: Support multiple employments.
    def selected_employment
      employments.any? ? employments.last : Employment.new
    end

    def ineligible?
      # TODO: Support multiple employments.
      selected_employment.ineligible? ||
        ineligible_qts_award_year? ||
        employed_at_no_school? ||
        current_school_closed? ||
        not_taught_enough?
    end

    def ineligibility_reason
      # TODO: Support multiple employments.
      if selected_employment.ineligible?
        selected_employment.ineligibility_reason
      else
        [
          :ineligible_qts_award_year,
          :employed_at_no_school,
          :current_school_closed,
          :not_taught_enough,
        ].find { |eligibility_check| send("#{eligibility_check}?") }
      end
    end

    private

    def ineligible_qts_award_year?
      awarded_qualified_status_before_2013?
    end

    def current_school_closed?
      current_school.present? && !current_school.open?
    end

    def not_taught_enough?
      mostly_performed_leadership_duties?
    end
  end
end
