require "rails_helper"

RSpec.describe Journeys::FurtherEducationPayments::AnswersPresenter do
  let(:journey) { Journeys::FurtherEducationPayments }
  let(:journey_session) { create(:further_education_payments_session, answers:) }

  describe "#eligibility_answers" do
    subject { described_class.new(journey_session).eligibility_answers }

    let(:college) { create(:school) }

    let(:teaching_responsibilities) { true }
    let(:school_id) { college.id }
    let(:contract_type) { "permanent" }
    let(:teaching_hours_per_week) { "more_than_12" }
    let(:further_education_teaching_start_year) { 2023 }
    let(:subjects_taught) { ["chemistry", "maths"] }
    let(:half_teaching_hours) { true }
    let(:teaching_qualification) { "yes" }
    let(:subject_to_formal_performance_action) { false }
    let(:subject_to_disciplinary_action) { false }

    let(:answers) {
      build(
        :further_education_payments_answers,
        teaching_responsibilities: teaching_responsibilities,
        school_id: school_id,
        contract_type: contract_type,
        teaching_hours_per_week: teaching_hours_per_week,
        further_education_teaching_start_year: further_education_teaching_start_year,
        subjects_taught: subjects_taught,
        half_teaching_hours: half_teaching_hours,
        teaching_qualification: teaching_qualification,
        subject_to_formal_performance_action: subject_to_formal_performance_action,
        subject_to_disciplinary_action: subject_to_disciplinary_action
      )
    }

    it {
      is_expected.to match_array(
        [
          ["Are you a member of staff with teaching responsibilities?", "Yes", "teaching-responsibilities"],
          ["Which FE provider are you employed by?", college.name, "further-education-provision-search"],
          ["What type of contract do you have with #{college.name}?", "Permanent contract", "contract-type"],
          ["On average, how many hours per week are you timetabled to teach at #{college.name} during the current term?", "More than 12 hours per week", "teaching-hours-per-week"],
          ["Which academic year did you start teaching in further education (FE) in England?", "September 2023 to August 2024", "further-education-teaching-start-year"],
          ["Which subject areas do you teach?", "<p class=\"govuk-body\">Chemistry</p><p class=\"govuk-body\">Maths</p>", "subjects-taught"],
          ["Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?", "Yes", "half-teaching-hours"],
          ["Do you have a teaching qualification?", "Yes", "teaching-qualification"],
          ["Have any performance measures been started against you?", "No", "poor-performance"],
          ["Are you currently subject to disciplinary action?", "No", "poor-performance"]
        ]
      )
    }

    context "contract_type - fixed_term" do
      let(:contract_type) { "fixed_term" }

      it { is_expected.to include(["What type of contract do you have with #{college.name}?", "Fixed-term contract", "contract-type"]) }
    end

    context "contract_type - variable_hours" do
      let(:contract_type) { "variable_hours" }

      it { is_expected.to include(["What type of contract do you have with #{college.name}?", "Variable hours contract", "contract-type"]) }
    end

    context "subjects-taught - just one" do
      let(:subjects_taught) { %w[building_construction] }

      it {
        is_expected.to include([
          "Which subject areas do you teach?",
          "<p class=\"govuk-body\">Building and construction</p>",
          "subjects-taught"
        ])
      }
    end

    context "subjects-taught - all of them" do
      let(:subjects_taught) { %w[building_construction chemistry computing early_years engineering_manufacturing maths physics] }

      it {
        is_expected.to include([
          "Which subject areas do you teach?",
          "<p class=\"govuk-body\">Building and construction</p><p class=\"govuk-body\">Chemistry</p><p class=\"govuk-body\">Computing, including digital and ICT</p><p class=\"govuk-body\">Early years</p><p class=\"govuk-body\">Engineering and manufacturing, including transport engineering and electronics</p><p class=\"govuk-body\">Maths</p><p class=\"govuk-body\">Physics</p>",
          "subjects-taught"
        ])
      }
    end
  end
end
