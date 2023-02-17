# frozen_string_literal: true

module SimplePolicyPayments
  class Eligibility < ApplicationRecord
    EDITABLE_ATTRIBUTES = [
      :current_school_id
    ].freeze
    AMENDABLE_ATTRIBUTES = [].freeze
    ATTRIBUTE_DEPENDENCIES = {}.freeze

    self.table_name = 'simple_policy_payments_eligibilities'

    has_one :claim, as: :eligibility, inverse_of: :eligibility
    belongs_to :current_school, optional: true, class_name: 'School'

    validates :current_school, on: [:'current-school', :submit], presence: { message: 'Select the school you teach at' }

    delegate :name, to: :current_school, prefix: true, allow_nil: true

    def policy
      SimplePolicyPayments
    end

    # Rescues from errors for assignments coming from LUP-only fields
    # eg. `claim.eligibility.eligible_degree_subject = true` will get ignored
    def assign_attributes(*args, **kwargs)
      super
    rescue ActiveRecord::UnknownAttributeError
      all_attributes_ignored = (args.first.keys - IGNORED_ATTRIBUTES).empty?
      raise unless all_attributes_ignored
    end

    def ineligible? = false

    def ineligibility_reason = []

    def award_amount = BigDecimal('10.00')

    def reset_dependent_answers(reset_attrs = [])
      attrs = ineligible? ? changed.concat(reset_attrs) : changed

      ATTRIBUTE_DEPENDENCIES.each do |attribute_name, dependent_attribute_names|
        dependent_attribute_names.each do |dependent_attribute_name|
          write_attribute(dependent_attribute_name, nil) if attrs.include?(attribute_name)
        end
      end
    end

    def submit!
      save!
    end
  end
end
