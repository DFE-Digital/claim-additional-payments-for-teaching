module Admin
  module AmendmentsHelper
    def amendment_errored_field_id_overrides(amendment)
      nested_claim_attributes_to_ids = Claim::AMENDABLE_ATTRIBUTES.to_h { |attribute|
        [attribute, "amendment_claim_#{attribute}"]
      }

      # If we have a validation error on claim_changes (because the user didn’t
      # change anything) there isn’t an obvious element to link to for them to
      # correct this error, so just use the first element in the form (TRN).
      claim_changes_attribute_to_id = {claim_changes: "amendment_claim_teacher_reference_number"}

      nested_claim_attributes_to_ids.merge(claim_changes_attribute_to_id)
    end
  end
end
