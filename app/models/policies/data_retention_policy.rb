module Policies
  class DataRetentionPolicy
    RETAINED = ->(_) { false }

    FIVE_ACADEMIC_YEARS = ->(claim_academic_year) do
      claim_academic_year <= AcademicYear.current - 5
    end

    def initialize(claim)
      unless claim.policy.is_a?(self.class.module_parent)
        raise ArgumentError, "Claim must be a #{self.class.module_parent} claim"
      end

      @claim = claim
    end

    def scrub!
      eligibility_attributes.each do |attribute_name, condition|
        if condition.call(claim.academic_year)
          claim.eligibility.assign_attributes("#{attribute_name}": nil)

          claim.eligibility.presonal_data_removed << {
            attribute: attribute_name.to_s,
            removed_at: Time.zone.now
          }

          claim.ammendments.each do |amendment|
            if ammendment.claim_changes.key?(attribute_name.to_s)
              amendment.claim_changes[attribute_name.to_s] = nil
              amendment.personal_data_removed_at = Time.zone.now
            end
          end

          answers = claim.journey_session&.answers || {}

          if answers.key?(attribute_name.to_s)
            answers[attribute_name.to_s] = nil
            claim.journey_session.assign_attributes(answers: answers)
          end
        end
      end

      claim_attributes.each do |attribute_name, condition|
        if condition.call(claim.academic_year)
          claim.assign_attributes("#{attribute_name}": nil)

          claim.ammendments.each do |amendment|
            amendment.claim_changes[attribute_name.to_s] = nil
            amendment.personal_data_removed_at = Time.zone.now
          end

          answers = claim.journey_session&.answers || {}

          if answers.key?(attribute_name.to_s)
            answers[attribute_name.to_s] = nil
            claim.journey_session.assign_attributes(answers: answers)
          end

          claim.presonal_data_removed << {
            attribute: attribute_name.to_s,
            removed_at: Time.zone.now
          }
        end
      end

      ApplicationRecord.transaction do
        claim.eligibility.save! if claim.eligibility.changed?
        claim.amendments.each(&:save!) if claim.amendments.any? { |a| a.changed? }
        claim.journey_session&.save!
        claim.save! if claim.changed?
      end
    end

    private

    attr_reader :claim

    def eligibility_attributes
      self.class::ELIGIBILITY_ATTRIBUTES
    end

    def claim_attributes
      self.class::CLAIM_ATTRIBUTES
    end
  end
end
