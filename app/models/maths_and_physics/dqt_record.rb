module MathsAndPhysics
  # Used to model a record in DQT for the Maths and Physics policy.
  #
  # Should be initialised with data from a row in the report
  # requested from the Database of Qualified Teachers.
  #
  # Determines the eligibility of a teacher's qualifications for
  # the Maths and Physics policy.
  #
  #   qts_award_date:     The date the teacher achieved qualified
  #                       teacher status.
  #   itt_subject_codes:  The corresponding JAC codes to the subject
  #                       specialism that the teacher competed their
  #                       initial teacher training in.
  #   degree_codes:       The corresponding JAC codes to the subject(s)
  #                       the teacher completed their degree in.
  class DQTRecord
    attr_reader :qts_award_date, :itt_subject_codes, :degree_codes

    # Full list of JAC principal subject codes can be found:
    # https://www.hesa.ac.uk/support/documentation/jacs/jacs3-principal
    #
    # Eligible JAC codes for this policy:
    # https://www.gov.uk/government/publications/additional-payments-for-teaching-eligibility-and-payment-details/claim-a-payment-for-teaching-maths-or-physics-eligibility-and-payment-details#teachers-qualifications
    ELIGIBLE_JAC_CODES = [
      "G1", # Mathematics
      "G2", # Operational research
      "G3", # Statistics
      "G9", # Others in mathematical sciences
      "F3" # Physics
    ].freeze

    # The row from a DQTReportCsv as a hash. Expected to contain the keys:
    # "dfeta qtsdate" -     A string representation of the date the teacher
    #                       achieved qualified teacher status.
    #                       Format: %-d/%-m/%Y
    # "ITTSub(n)Value" -    A string value containing the teacher's ITT subject
    #                       specialism JAC code.
    # "HESubject(n)Value" - A string value containing the teacher's
    #                       undergraduate or postgraduate degree JAC code
    def initialize(data)
      @qts_award_date = Date.parse(data.fetch("dfeta qtsdate"))
      @itt_subject_codes = data.slice("ITTSub1Value", "ITTSub2Value", "ITTSub3Value").compact.values
      @degree_codes = data.slice("HESubject1Value", "HESubject2Value", "HESubject3Value").compact.values
    end

    def eligible?
      eligible_qts_date? && eligible_qualification_subject?
    end

    private

    def eligible_qts_date?
      AcademicYear.for(qts_award_date) >= MathsAndPhysics.first_eligible_qts_award_year
    end

    def eligible_qualification_subject?
      itt_subject_maths_or_physics? || maths_or_physics_degree?
    end

    def itt_subject_maths_or_physics?
      itt_subject_codes.any? { |jac_code| jac_code.start_with?(*ELIGIBLE_JAC_CODES) }
    end

    def maths_or_physics_degree?
      degree_codes.any? { |jac_code| jac_code.start_with?(*ELIGIBLE_JAC_CODES) }
    end
  end
end
