module StudentLoans
  class SchoolEligibility
    POLICY_START_DATE = Date.new(2018, 4, 6)
    ELIGIBLE_LOCAL_AUTHORITY_CODES = [
      370, # Barnsley
      890, # Blackpool
      867, # Bracknell Forest
      380, # Bradford
      873, # Cambridgeshire
      831, # Derby
      830, # Derbyshire
      371, # Doncaster
      876, # Halton
      340, # Knowsley
      821, # Luton
      806, # Middlesbrough
      926, # Norfolk
      812, # North-east Lincolnshire
      815, # North Yorkshire
      928, # Northamptonshire
      929, # Northumberland
      353, # Oldham
      874, # Peterborough
      851, # Portsmouth
      355, # Salford
      343, # Sefton
      342, # St Helens
      861, # Stoke-on-Trent
      935, # Suffolk
    ].freeze

    def initialize(school)
      @school = school
    end

    def eligible_claim_school?
      !closed_before_policy_start? &&
        eligible_local_authority? &&
        (@school.state_funded? || @school.secure_unit?) &&
        (@school.secondary_phase? || @school.secondary_equivalent_special? || @school.secondary_equivalent_alternative_provision?)
    end

    def eligible_current_school?
      @school.open? &&
        (@school.state_funded? || @school.secure_unit?) &&
        (@school.secondary_phase? || @school.secondary_equivalent_special? || @school.secondary_equivalent_alternative_provision?)
    end

    private

    def eligible_local_authority?
      ELIGIBLE_LOCAL_AUTHORITY_CODES.include?(@school.local_authority.code)
    end

    def closed_before_policy_start?
      @school.close_date.present? && @school.close_date < POLICY_START_DATE
    end
  end
end
