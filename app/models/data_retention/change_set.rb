# Applies a data retention schedule to a claim and eligibility
# Returns new claim and eligibility attributes with redacted values
# according to the data retention schedule.
# Updates the legacy personal_data_removed_at to the current time unless
# already set.
# Updates the redacted_attributes JSONB column with the attributes we've
# changed.
module DataRetention
  class ChangeSet
    attr_reader \
      :claim,
      :retention_schedule,
      :evaluation_context

    def initialize(claim:, retention_schedule:, evaluation_context:)
      @claim = claim
      @retention_schedule = retention_schedule
      @evaluation_context = evaluation_context
    end

    # Hash of all attributes on the claim defined in the data retention
    # schedule with redactions performed, and meta data updated, suitable for
    # passing to Claim#update!
    def new_claim_attributes
      @new_claim_attributes || claim.attributes.to_h do |name, value|
        if claim_attribute_changed?(name)
          [name, nil]
        else
          [name, value]
        end
      end.merge(
        redacted_attributes: claim.redacted_attributes.to_h.merge(new_redacted_claim_attributes),
        personal_data_removed_at: claim.personal_data_removed_at.presence || DateTime.current
      )
    end

    # Hash of all attributes on the eligibility defined in the data retention
    # schedule with redactions performed, and meta data updated, suitable for
    # passing to Elgibility#update!
    def new_eligibility_attributes
      @new_eligibility_attributes || claim.eligibility.attributes.to_h do |name, value|
        if eligibility_attribute_changed?(name)
          [name, nil]
        else
          [name, value]
        end
      end.merge(
        redacted_attributes: claim.eligibility.redacted_attributes.to_h.merge(new_redacted_eligibility_attributes)
      )
    end

    # Given an amendment returns a new hash of attributes with claim changes
    # updated.
    def new_amendment_attributes(amendment)
      changed = false

      new_claim_changes = amendment.claim_changes.to_h do |name, value|
        if attribute_changed?(name)
          changed = true
          [name, nil]
        else
          [name, value]
        end
      end

      return amendment.attributes unless changed

      personal_data_removed_at = amendment.personal_data_removed_at.presence || DateTime.current

      amendment.attributes.merge(
        claim_changes: new_claim_changes,
        personal_data_removed_at: personal_data_removed_at
      )
    end

    def expired_eligibility_attachments
      retention_schedule.eligibility_attachments_to_destroy.flat_map do |name, attribute|
        claim.eligibility.public_send(name).to_a if expired_eligibility_attributes.include?(attribute.to_s)
      end.compact
    end

    def attribute_changed?(attr)
      claim_attribute_changed?(attr) || eligibility_attribute_changed?(attr)
    end

    def any_changes?
      expired_claim_attributes.any? || expired_eligibility_attributes.any?
    end

    private

    def claim_attribute_changed?(attr)
      expired_claim_attributes.include?(attr.to_s)
    end

    def eligibility_attribute_changed?(attr)
      expired_eligibility_attributes.include?(attr.to_s)
    end

    def expired_claim_attributes
      @expired_claim_attributes ||= retention_schedule.claim_attributes.select do |attr, condition|
        current_value = claim.send(attr)
        !current_value.nil? && evaluation_context.condition_met?(condition)
      end.keys.map(&:to_s)
    end

    def new_redacted_claim_attributes
      @new_redacted_claim_attributes ||= expired_claim_attributes.to_h do |name|
        [name, DateTime.current]
      end
    end

    def expired_eligibility_attributes
      @expired_eligibility_attributes ||= retention_schedule.eligibility_attributes.select do |attr, condition|
        current_value = claim.eligibility.send(attr)
        !current_value.nil? && evaluation_context.condition_met?(condition)
      end.keys.map(&:to_s)
    end

    def new_redacted_eligibility_attributes
      @new_redacted_eligibility_attributes ||= expired_eligibility_attributes.to_h do |name|
        [name, DateTime.current]
      end
    end
  end
end
