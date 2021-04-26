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
  #   itt_subject_codes:  The corresponding JAC codes or HECOS to the subject
  #                       specialism that the teacher competed their
  #                       initial teacher training in.
  #   degree_codes:       The corresponding JAC codes or HECOS to the subject(s)
  #                       the teacher completed their degree in.
  class DqtRecord
    attr_reader :qts_award_date, :itt_subject_codes, :degree_codes

    # Full list of JAC principal subject codes can be found:
    # https://www.hesa.ac.uk/support/documentation/jacs/jacs3-principal
    #
    # Further information on the HECOS codes and their mapping against the JACS codes can be found:
    # https://www.hesa.ac.uk/innovation/hecos
    #
    # Eligible JAC codes and HECOs codes for this policy:
    # https://www.gov.uk/government/publications/additional-payments-for-teaching-eligibility-and-payment-details/claim-a-payment-for-teaching-maths-or-physics-eligibility-and-payment-details#teachers-qualifications
    ELIGIBLE_JAC_CODES = [
      "G1", # Mathematics
      "G2", # Operational research
      "G3", # Statistics
      "G9", # Others in mathematical sciences
      "F3" # Physics
    ].freeze

    ELIGIBLE_MATHS_HECOS_CODES = [
      "100400", # Applied mathematics
      "100401", # Financial mathematics
      "100402", # Mathematical modelling
      "100403", # Mathematics
      "100404", # Operational research
      "100405", # Pure mathematics
      "100406", # Statistics
      "101027", # Numerical analysis
      "101028", # Engineering and industrial mathematics
      "101029", # Computational mathematics
      "101030", # Applied statistics
      "101031", # Medical statistics
      "101032", # Probability
      "101033", # Stochastic processes
      "101034" # Statistical modelling
    ].freeze

    ELIGIBLE_PHYSICS_HECOS_CODES = [
      "100416", # Chemical physics
      "100419", # Medical physics
      "100425", # Physics
      "100426", # Theoretical physics
      "101060", # Applied physics
      "101061", # Engineering physics
      "101068", # Atmospheric physics
      "101071", # Computational physics
      "101074", # Radiation physics
      "101075", # Photonics and Optical physics
      "101076", # Laser physics
      "101077", # Nuclear and Particle physics
      "101223", # Condensed matter physics
      "101300", # Quantum theory and Applications
      "101390", # Marine physics
      "101391" # Electromagnetism
    ].freeze

    # The record transformed from a DQTReportCsv. Expected to contain the keys:
    # :qts_date              - The date the teacher achieved qualified teacher
    #                          status.
    #                          Format: %d/%m/%Y
    # :itt_subject_codes - An array of the claimants ITT subject JAC or HECOS codes.
    # :degree_codes      - An array of the claimants degree JAC or HECOS codes.
    # Previously only JAC codes were checked, however changes to the DQT mean subject codes can be either JACS or HECOS codes.

    def initialize(record)
      @qts_award_date = record.fetch(:qts_date)
      @itt_subject_codes = record.fetch(:itt_subject_codes)
      @degree_codes = record.fetch(:degree_codes)
    end

    def eligible?
      eligible_qts_date? && eligible_qualification_subject?
    end

    private

    def eligible_qts_date?
      qts_award_date.present? && AcademicYear.for(qts_award_date) >= MathsAndPhysics.first_eligible_qts_award_year
    end

    def eligible_qualification_subject?
      itt_subject_maths_or_physics? || maths_or_physics_degree?
    end

    def itt_subject_maths_or_physics?
      itt_subject_codes.any? { |subject_code|
        subject_code.start_with?(*ELIGIBLE_JAC_CODES) ||
          ELIGIBLE_MATHS_HECOS_CODES.include?(subject_code) ||
          ELIGIBLE_PHYSICS_HECOS_CODES.include?(subject_code)
      }
    end

    def maths_or_physics_degree?
      degree_codes.any? { |subject_code|
        subject_code.start_with?(*ELIGIBLE_JAC_CODES) ||
          ELIGIBLE_MATHS_HECOS_CODES.include?(subject_code) ||
          ELIGIBLE_PHYSICS_HECOS_CODES.include?(subject_code)
      }
    end
  end
end
