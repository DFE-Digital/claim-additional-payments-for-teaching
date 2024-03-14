module Irp
  class Eligibility < ApplicationRecord
    EDITABLE_ATTRIBUTES = [
      :one_year,
      :state_funded_secondary_school,
      :date_of_entry,
      :start_date,
      :application_route,
      :ip_address,
      :nationality,
      :passport_number,
      :school_headteacher_name,
      :school_name,
      :school_address_line_1,
      :school_address_line_2,
      :school_city,
      :school_postcode,
      :subject,
      :visa_type
    ].freeze
    AMENDABLE_ATTRIBUTES = [].freeze
    ATTRIBUTE_DEPENDENCIES = {}.freeze

    def current_school
      Struct.new(:open?, :name, :phone_number, :urn, :dfe_number).new(true, school_name, "01 811 8055", "dummy_urn", "dummy_dfe_number")
    end

    self.table_name = "irp_eligibilities"

    has_one :claim, as: :eligibility, inverse_of: :eligibility
    # TODO: How to fix current school - we've got School Name?
    belongs_to :current_school, optional: true, class_name: "School"

    validates :one_year, presence: {message: "Must be present"}
    validates :state_funded_secondary_school, presence: {message: "Must be present"}
    validates :date_of_entry, presence: {message: "Must be present"}
    validates :start_date, presence: {message: "Must be present"}
    validates :application_route, presence: {message: "Must be present"}
    validates :ip_address, presence: {message: "Must be present"}
    validates :nationality, presence: {message: "Must be present"}
    validates :passport_number, presence: {message: "Must be present"}
    validates :school_headteacher_name, presence: {message: "Must be present"}
    validates :school_name, presence: {message: "Must be present"}
    validates :school_address_line_1, presence: {message: "Must be present"}
    validates :school_city, presence: {message: "Must be present"}
    validates :school_postcode, presence: {message: "Must be present"}
    validates :subject, presence: {message: "Must be present"}
    validates :visa_type, presence: {message: "Must be present"}

    delegate :name, to: :current_school, prefix: true, allow_nil: true
    delegate :academic_year, to: :claim, prefix: true

    def policy
      Irp
    end

    def ineligible?
    end

    def ineligibility_reason
      [].find { |eligibility_check| send(:"#{eligibility_check}?") }
    end

    def award_amount
      BigDecimal("10000.00")
    end

    def submit!
      save!
    end
  end
end
