require "rails_helper"

RSpec.describe Policies::FurtherEducationPayments::EligibilityAdminAnswersPresenter do
  let(:school) do
    create(
      :school,
      :further_education,
      :fe_eligible,
      name: "Springfield Elementary"
    )
  end

  let(:contract_type) { "permanent" }
  let(:fixed_term_full_year) { nil }
  let(:teaching_hours_per_week) { "more_than_12" }
  let(:teaching_hours_per_week_next_term) { nil }
  let(:taught_at_least_one_term) { nil }

  let(:claim) do
    create(
      :claim,
      academic_year: AcademicYear.new(2024)
    )
  end

  let(:eligibility) do
    create(
      :further_education_payments_eligibility,
      :eligible,
      claim: claim,
      school: school,
      teaching_responsibilities: true,
      contract_type: contract_type,
      fixed_term_full_year: fixed_term_full_year,
      teaching_hours_per_week: teaching_hours_per_week,
      teaching_hours_per_week_next_term: teaching_hours_per_week_next_term,
      taught_at_least_one_term: taught_at_least_one_term,
      further_education_teaching_start_year: "2023",
      subjects_taught: ["maths", "engineering_manufacturing"],
      maths_courses: ["approved_level_321_maths", "gcse_maths"],
      engineering_manufacturing_courses: ["approved_level_321_engineering"],
      hours_teaching_eligible_subjects: true,
      half_teaching_hours: true,
      teaching_qualification: "no_but_planned",
      subject_to_formal_performance_action: false,
      subject_to_disciplinary_action: false,
      award_amount: 6_000
    )
  end

  let(:presenter) { described_class.new(eligibility) }

  describe "provider_details" do
    subject { presenter.provider_details }

    it do
      is_expected.to include(
        [
          "Are you a member of staff with teaching responsibilities?",
          "Yes"
        ],
        [
          "Which FE provider are you employed by?",
          "Springfield Elementary"
        ]
      )
    end
  end

  describe "#employment_contract" do
    subject { presenter.employment_contract }

    context "with a permant contract claim" do
      let(:contract_type) { "permanent" }
      let(:teaching_hours_per_week) { "more_than_12" }

      it do
        is_expected.to match_array(
          [
            [
              "What type of contract do you have with Springfield Elementary?",
              "Permanent contract (including full-time and part-time contracts)"
            ],
            [
              "On average, how many hours per week are you timetabled to teach at Springfield Elementary during the current term?",
              "12 hours or more per week"
            ]
          ]
        )
      end
    end

    context "with a variable_hours contract claim" do
      let(:contract_type) { "variable_hours" }
      let(:teaching_hours_per_week) { "less_than_2_5" }
      let(:teaching_hours_per_week_next_term) { "at_least_2_5" }
      let(:taught_at_least_one_term) { true }

      it do
        is_expected.to match_array(
          [
            [
              "What type of contract do you have with Springfield Elementary?",
              "Variable hours contract (This includes zero hours contracts)"
            ],
            [
              "Have you taught at Springfield Elementary for at least one academic term?",
              "Yes, I have taught at Springfield Elementary for at least one academic term"
            ],
            [
              "On average, how many hours per week are you timetabled to teach at Springfield Elementary during the current term?",
              "Less than 2.5 hours per week"
            ],
            [
              "Are you timetabled to teach at least 2.5 hours per week at Springfield Elementary next term?",
              "Yes, I am timetabled to teach at least 2.5 hours per week at Springfield Elementary next term"
            ]
          ]
        )
      end
    end

    context "with a fixed term contract claim" do
      let(:contract_type) { "fixed_term" }
      let(:teaching_hours_per_week) { "between_2_5_and_12" }
      let(:teaching_hours_per_week_next_term) { "at_least_2_5" }

      context "with a full year contract" do
        let(:fixed_term_full_year) { true }

        it do
          is_expected.to match_array(
            [
              [
                "What type of contract do you have with Springfield Elementary?",
                "Fixed term contract"
              ],
              [
                "Does your fixed-term contract cover the full 2024 to 2025 academic year?",
                "Yes, it covers the full 2024 to 2025 academic year"
              ],
              [
                "On average, how many hours per week are you timetabled to teach at Springfield Elementary during the current term?",
                "2.5 hours or more but less than 12 hours per week"
              ],
              [
                "Are you timetabled to teach at least 2.5 hours per week at Springfield Elementary next term?",
                "Yes, I am timetabled to teach at least 2.5 hours per week at Springfield Elementary next term"
              ]
            ]
          )
        end
      end

      context "without a full year contract" do
        let(:fixed_term_full_year) { false }
        let(:teaching_hours_per_week_next_term) { "less_than_2_5" }
        let(:taught_at_least_one_term) { false }

        it do
          is_expected.to match_array(
            [
              [
                "What type of contract do you have with Springfield Elementary?",
                "Fixed term contract"
              ],
              [
                "Have you taught at Springfield Elementary for at least one academic term?",
                "No, I have not taught at Springfield Elementary for at least one academic term"
              ],
              [
                "Does your fixed-term contract cover the full 2024 to 2025 academic year?",
                "No, it does not cover the full 2024 to 2025 academic year"
              ],
              [
                "On average, how many hours per week are you timetabled to teach at Springfield Elementary during the current term?",
                "2.5 hours or more but less than 12 hours per week"
              ],
              [
                "Are you timetabled to teach at least 2.5 hours per week at Springfield Elementary next term?",
                "No, I’m not timetabled to teach at least 2.5 hours per week at Springfield Elementary next term"
              ]
            ]
          )
        end
      end
    end
  end

  describe "#academic_year_claimant_started_teaching" do
    subject { presenter.academic_year_claimant_started_teaching }

    it do
      is_expected.to eq(
        [
          [
            "Which academic year did you start teaching in further education (FE) in England?",
            "September 2023 to August 2024"
          ]
        ]
      )
    end
  end

  describe "#subjects_taught" do
    subject { presenter.subjects_taught }

    it do
      is_expected.to eq(
        [
          [
            "Which subject areas do you teach?",
            ["Maths", "Engineering and manufacturing, including transport engineering and electronics"]
          ],
          [
            "Maths courses",
            [
              "Qualifications approved for funding at level 3 and below in the <a class=\"govuk-link\" target=\"_blank\" rel=\"noreferrer noopener\" href=\"https://www.qualifications.education.gov.uk/Search?Status=All&amp;Level=0,1,2,3,4&amp;Sub=28&amp;PageSize=10&amp;Sort=Status\">mathematics and statistics (opens in new tab)</a> sector subject area",
              "GCSE in maths, functional skills qualifications and <a class=\"govuk-link\" target=\"_blank\" rel=\"noreferrer noopener\" href=\"https://submit-learner-data.service.gov.uk/find-a-learning-aim/LearningAimSearchResult?TeachingYear=2425&amp;HasFilters=False&amp;EFAFundingConditions=EFACONFUNDMATHS\">other maths qualifications (opens in new tab)</a> approved for teaching to 16 to 19-year-olds who meet the condition of funding"
            ]
          ],
          [
            "Engineering and manufacturing courses",
            [
              "Qualifications approved for funding at level 3 and below in the <a class=\"govuk-link\" target=\"_blank\" rel=\"noreferrer noopener\" href=\"https://www.qualifications.education.gov.uk/Search?Status=All&amp;Level=0,1,2,3,4&amp;Sub=15&amp;PageSize=10&amp;Sort=Status\">engineering (opens in new tab)</a> sector subject area"
            ]
          ]
        ]
      )
    end
  end

  describe "#teaching_hours" do
    subject { presenter.teaching_hours }

    it do
      is_expected.to eq(
        [
          [
            "Do you spend at least half of your timetabled teaching hours teaching these eligible courses?",
            "Yes"
          ],
          [
            "Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?",
            "Yes"
          ]
        ]
      )
    end
  end

  describe "#teaching_qualification" do
    subject { presenter.teaching_qualification }

    it do
      is_expected.to eq(
        [
          [
            "Do you have a teaching qualification?",
            "No, but I plan to enrol on one in the next 12 months"
          ]
        ]
      )
    end
  end

  describe "#performance_and_disciplinary_measures" do
    subject { presenter.performance_and_disciplinary_measures }

    it do
      is_expected.to eq(
        [
          [
            "Are you currently subject to disciplinary action?",
            "No"
          ],
          [
            "Have any performance measures been started against you?",
            "No"
          ]
        ]
      )
    end
  end

  describe "#policy_options_provided" do
    subject { presenter.policy_options_provided }

    it do
      is_expected.to eq(
        [
          [
            "Further Education Targeted Retention Incentive",
            "£6,000"
          ]
        ]
      )
    end
  end
end
