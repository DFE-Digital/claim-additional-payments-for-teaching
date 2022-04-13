module LevellingUpPayments
  # Checks if the subject studied, ITT'd and a teacher's teaching timetable are eligible
  # for LUP. This is necessary but not sufficient to award LUP.
  #
  # We might want to split this class because there's more than one reason this class
  # could change (check for eligible ITT, check for related degree, change in general
  # eligibility rules, etc.).
  #
  # Eligible ITT and degree codes could be stored in a table or hardcoded.
  class SubjectEligibility
    def initialize(itt_subject:, degree_subject:, teaching:)
      raise "nil teaching" if teaching.nil?

      @itt_subject = itt_subject
      @degree_subject = degree_subject
      @teaching = teaching
    end

    def eligible?
      qualified_teacher_status? and specialist? and eligible_teaching?
    end

    private

    def qualified_teacher_status?
      @itt_subject.present? and @degree_subject.present?
    end

    def specialist?
      eligible_itt? or eligible_degree?
    end

    # There's a spreadsheet of eligible ITT codes. Someone might know a pattern to them but
    # it's not immediately obvious.
    def eligible_itt?
      @itt_subject.eligible?
    end

    # There's a spreadsheet of eligible degrees. This will be decided by the newer HECoS code
    # (but might need the older JACS3 code). There are pattens to eligible HECoS and JACS3 codes
    # which might mean we can exploit string matching rather than maintain an exhaustive list
    # of all eligible codes.
    def eligible_degree?
      @degree_subject.eligible?
    end

    def eligible_teaching?
      # not sure how we get the mix of subjects being taught by a particular teacher
      # or whether we simply ask "do you spend 50% or more of your time teaching eligible subjects?"
      @teaching.teaching_eligible_subjects_fifty_percent_or_more?
    end
  end
end
