module Mptr
  class SchoolEligibility
    ELIGIBLE_PHASES = %w[secondary middle_deemed_secondary].freeze
    STATE_FUNDED_TYPE_GROUPS = %w[colleges la_maintained special_schools academies free_schools].freeze
    ELIGIBLE_LOCAL_AUTHORITY_DISTRICT_CODES = [
      "E08000016", # Barnsley
      "E06000009", # Blackpool
      "E08000032", # Bradford
      "E08000033", # Calderdale
      "E06000047", # County Durham
      "E07000163", # Craven
      "E06000005", # Darlington
      "E06000015", # Derby
      "E08000017", # Doncaster
      "E07000009", # East Cambridgeshire aka Fenland and East Cambridgeshire
      "E06000011", # East Riding of Yorkshire
      "E07000010", # Fenland aka Fenland and East Cambridgeshire
      "E08000037", # Gateshead
      "E07000164", # Hambleton
      "E07000165", # Harrogate
      "E06000001", # Hartlepool
      "E07000062", # Hastings
      "E07000202", # Ipswich
      "E06000010", # Kingston upon Hull, city of aka Kingston upon Hull
      "E08000034", # Kirklees
      "E08000035", # Leeds
      "E06000002", # Middlesbrough
      "E08000021", # Newcastle upon Tyne
      "E06000012", # North East Lincolnshire
      "E06000013", # North Lincolnshire
      "E08000022", # North Tyneside
      "E06000057", # Northumberland
      "E07000148", # Norwich
      "E08000004", # Oldham
      "E06000003", # Redcar and Cleveland
      "E07000166", # Richmondshire
      "E08000018", # Rotherham
      "E07000167", # Ryedale
      "E07000168", # Scarborough
      "E07000169", # Selby
      "E08000019", # Sheffield
      "E08000023", # South Tyneside
      "E06000004", # Stockton-on-Tees
      "E06000021", # Stoke-on-Trent
      "E08000024", # Sunderland
      "E08000036", # Wakefield
      "E07000191", # West Somerset
      "E06000014", # York
    ].freeze

    def initialize(school)
      @school = school
    end

    def check
      eligible_local_authority_district? && state_funded? && eligible_phase?
    end

    private

    def eligible_local_authority_district?
      ELIGIBLE_LOCAL_AUTHORITY_DISTRICT_CODES.include?(@school.local_authority_district.code)
    end

    def state_funded?
      STATE_FUNDED_TYPE_GROUPS.include?(@school.school_type_group) &&
        !independent_special_school?
    end

    def eligible_phase?
      ELIGIBLE_PHASES.include?(@school.phase)
    end

    def independent_special_school?
      @school.school_type == "other_independent_special_school"
    end
  end
end
