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

    ELIGIBLE_ITT_CODES = [
      "101038",
      "100358",
      "101060",
      "100417",
      "100366",
      "100403",
      "100425",
      "G100",
      "I200",
      "F110",
      "F1100",
      "G510",
      "I900",
      "G1100",
      "F310",
      "F3300",
      "F1001",
      "F1600",
      "F100",
      "G9009",
      "G5401",
      "G5400",
      "G5007",
      "G5001",
      "I100",
      "G5000",
      "G5003",
      "G5402",
      "G9007",
      "G5006",
      "F140",
      "G5602",
      "G500",
      "P2000",
      "P2001",
      "G5601",
      "G5604",
      "F1901",
      "G1401",
      "J9201",
      "F3200",
      "G1500",
      "G1400",
      "G5004",
      "G9005",
      "G9006",
      "G9003",
      "G1502",
      "G5009",
      "F3007",
      "G5005",
      "G9002",
      "F300",
      "F9623",
      "F9632",
      "F9613",
      "F390",
      "F6007",
      "F6006",
      "G1200",
      "F9626",
      "G1501",
      "F9625",
      "F1004",
      "F3012",
      "G4000",
      "G5008",
      "G9004",
      "F3201"
    ]

    def initialize(record, claim)
      @claim = claim
      @record = record
    end

    def eligible?
      (ELIGIBLE_ITT_CODES & degree_codes).present?
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
