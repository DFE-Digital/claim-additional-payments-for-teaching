# TODO - This is a placeholder implementation. It prevents ClaimVerifierJob
# failing and ensures the qualifications check works
module LevellingUpPremiumPayments
  class DqtRecord
    delegate(
      :qts_award_date,
      :itt_subjects,
      :itt_subject_codes,
      :itt_start_date,
      :degree_codes,
      :qualification_name,
      :degree_codes,
      to: :record
    )

    def initialize(record, claim)
      @claim = claim
      @record = record
    end

    # TODO
    def eligible?
      true
    end

    # TODO
    def eligible_qts_award_date?
      true
    end

    # TODO
    def eligible_qualification_subject?
      true
    end

    private

    attr_reader :claim, :record
  end
end
