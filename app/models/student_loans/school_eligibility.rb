module StudentLoans
  class SchoolEligibility
    ELIGIBLE_PHASES = %w[secondary middle_deemed_secondary].freeze
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

    def check
      eligible_local_authority? && @school.state_funded? && (eligible_phase? || eligible_special_school?)
    end

    private

    def eligible_local_authority?
      ELIGIBLE_LOCAL_AUTHORITY_CODES.include?(@school.local_authority.code)
    end

    def eligible_phase?
      ELIGIBLE_PHASES.include?(@school.phase)
    end

    def eligible_special_school?
      @school.phase == "not_applicable" && @school.special? && @school.school_type != "special_post_16_institutions"
    end
  end
end
