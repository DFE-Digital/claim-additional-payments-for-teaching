require "journey_subject_eligibility_checker"

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

    ELIGIBLE_JAC_CODES = [
      "F100",
      "F110",
      "F111",
      "F112",
      "F120",
      "F130",
      "F131",
      "F140",
      "F141",
      "F150",
      "F151",
      "F160",
      "F161",
      "F162",
      "F163",
      "F164",
      "F165",
      "F170",
      "F180",
      "F190",
      "F300",
      "F310",
      "F311",
      "F320",
      "F321",
      "F330",
      "F331",
      "F332",
      "F340",
      "F341",
      "F342",
      "F343",
      "F350",
      "F351",
      "F360",
      "F361",
      "F370",
      "F380",
      "F390",
      "F500",
      "F510",
      "F520",
      "F521",
      "F522",
      "F530",
      "F540",
      "F550",
      "F590",
      "G000",
      "G100",
      "G110",
      "G120",
      "G121",
      "G130",
      "G140",
      "G150",
      "G160",
      "G170",
      "G190",
      "G200",
      "G290",
      "G300",
      "G310",
      "G311",
      "G320",
      "G330",
      "G340",
      "G350",
      "G390",
      "G900",
      "I000",
      "I100",
      "I110",
      "I111",
      "I112",
      "I113",
      "I114",
      "I115",
      "I120",
      "I130",
      "I140",
      "I150",
      "I160",
      "I161",
      "I190",
      "I200",
      "I210",
      "I220",
      "I230",
      "I240",
      "I250",
      "I260",
      "I270",
      "I290",
      "I300",
      "I310",
      "I320",
      "I321",
      "I322",
      "I323",
      "I390",
      "I400",
      "I410",
      "I420",
      "I430",
      "I440",
      "I450",
      "I460",
      "I461",
      "I490",
      "I500",
      "I510",
      "I520",
      "I530",
      "I590",
      "I600",
      "I610",
      "I620",
      "I630",
      "I700",
      "I710",
      "I900",
      "I990"
    ].freeze

    ELIGIBLE_HECOS_CODES = [
      "100065",
      "100162",
      "100260",
      "100265",
      "100344",
      "100358",
      "100359",
      "100360",
      "100361",
      "100362",
      "100363",
      "100365",
      "100366",
      "100367",
      "100368",
      "100371",
      "100372",
      "100373",
      "100374",
      "100376",
      "100385",
      "100390",
      "100392",
      "100396",
      "100400",
      "100401",
      "100402",
      "100403",
      "100404",
      "100405",
      "100406",
      "100413",
      "100414",
      "100415",
      "100416",
      "100417",
      "100419",
      "100420",
      "100422",
      "100423",
      "100425",
      "100426",
      "100427",
      "100430",
      "100734",
      "100735",
      "100736",
      "100737",
      "100738",
      "100741",
      "100751",
      "100753",
      "100754",
      "100755",
      "100756",
      "100757",
      "100821",
      "100869",
      "100956",
      "100960",
      "100961",
      "100963",
      "100966",
      "100968",
      "100989",
      "100992",
      "100994",
      "101019",
      "101020",
      "101027",
      "101028",
      "101029",
      "101030",
      "101031",
      "101032",
      "101033",
      "101034",
      "101038",
      "101041",
      "101042",
      "101043",
      "101044",
      "101045",
      "101046",
      "101050",
      "101053",
      "101054",
      "101060",
      "101061",
      "101068",
      "101071",
      "101074",
      "101075",
      "101076",
      "101077",
      "101102",
      "101103",
      "101223",
      "101234",
      "101243",
      "101267",
      "101268",
      "101300",
      "101389",
      "101390",
      "101391",
      "101400"
    ].freeze

    ELIGIBLE_ITT_SUBJECTS = {
      chemistry: [
        "applied chemistry"
      ],
      foreign_languages: [
        "French language"
      ],
      mathematics: [
        "mathematics"
      ],
      physics: [
        "applied physics"
      ],
      computing: [
        "Applied ICT",
        "computer science"
      ]
    }

    def initialize(record, claim)
      @record = record
      @claim = claim
    end

    def eligible?
      matching_type = Dqt::Codes::QUALIFICATION_MATCHING_TYPE.find { |key, values|
        values.include?(qualification_name)
      }&.first

      date = case matching_type
      when :under, :other
        qts_award_date
      when :post
        itt_start_date
      end

      policy_year = PolicyConfiguration.for(claim.policy).current_academic_year
      itt_year = AcademicYear.for(date)
      eligible_itt_years = JourneySubjectEligibilityChecker.selectable_itt_years_for_claim_year(policy_year)

      (eligible_code?(itt_subject_codes) || eligible_code?(degree_codes)) && eligible_itt_years.include?(itt_year) && eligible_subject?
    end

    private

    attr_reader :record, :claim

    def eligible_code?(code)
      ((ELIGIBLE_JAC_CODES | ELIGIBLE_HECOS_CODES) & code).present?
    end

    def eligible_subject?
      return true if claim.eligibility.itt_subject_none_of_the_above?

      (ELIGIBLE_ITT_SUBJECTS[claim.eligibility.eligible_itt_subject.to_sym] & itt_subjects).present?
    end
  end
end
