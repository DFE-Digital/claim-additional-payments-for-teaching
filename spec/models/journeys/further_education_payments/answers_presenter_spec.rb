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
    let(:further_education_teaching_start_year) { "2023" }
    let(:subjects_taught) { ["chemistry", "maths"] }
    let(:half_teaching_hours) { true }
    let(:teaching_qualification) { "yes" }
    let(:subject_to_formal_performance_action) { false }
    let(:subject_to_disciplinary_action) { false }

    let(:building_construction_courses) {
      %w[
        level3_buildingconstruction_approved
        tlevel_building
        tlevel_onsiteconstruction
        tlevel_design_surveying
        level2_3_apprenticeship
      ]
    }

    let(:chemistry_courses) {
      %w[
        alevel_chemistry
        gcse_chemistry
        ibo_level_3_chemistry
        ibo_level_1_2_myp_chemistry
      ]
    }

    let(:computing_courses) {
      %w[
        level3_and_below_ict_for_practitioners
        level3_and_below_ict_for_users
        digitalskills_quals
        tlevel_digitalsupport
        tlevel_digitalbusiness
        tlevel_digitalproduction
        ibo_level3_compsci
        level2_3_apprenticeship
      ]
    }

    let(:early_years_courses) {
      %w[
        eylevel2
        eylevel3
        eytlevel
        coursetoeyq
      ]
    }

    let(:engineering_manufacturing_courses) {
      %w[
        approved_level_321_engineering
        approved_level_321_manufacturing
        approved_level_321_transportation
        tlevel_design
        tlevel_maintenance
        tlevel_engineering
        level2_3_apprenticeship
      ]
    }

    let(:maths_courses) {
      %w[
        approved_level_321_maths
        gcse_maths
      ]
    }

    let(:physics_courses) {
      %w[
        alevel_physics
        gcse_physics
        ibo_level_1_2_myp_physics
        ibo_level_3_physics
      ]
    }

    let(:answers) {
      build(
        :further_education_payments_answers,
        teaching_responsibilities: teaching_responsibilities,
        school_id: school_id,
        contract_type: contract_type,
        teaching_hours_per_week: teaching_hours_per_week,
        further_education_teaching_start_year: further_education_teaching_start_year,
        subjects_taught: subjects_taught,
        hours_teaching_eligible_subjects: true,
        half_teaching_hours: half_teaching_hours,
        teaching_qualification: teaching_qualification,
        subject_to_formal_performance_action: subject_to_formal_performance_action,
        subject_to_disciplinary_action: subject_to_disciplinary_action,
        building_construction_courses: building_construction_courses,
        chemistry_courses: chemistry_courses,
        computing_courses: computing_courses,
        early_years_courses: early_years_courses,
        engineering_manufacturing_courses: engineering_manufacturing_courses,
        maths_courses: maths_courses,
        physics_courses: physics_courses
      )
    }

    it {
      is_expected.to match_array(
        [
          ["Are you a member of staff with teaching responsibilities?",
            "Yes",
            "teaching-responsibilities"],
          ["Which FE provider directly employs you?",
            college.name,
            "further-education-provision-search"],
          ["What type of contract do you have with #{college.name}?",
            "Permanent contract",
            "contract-type"],
          ["On average, how many hours per week are you timetabled to teach at #{college.name} during the current term?",
            "More than 12 hours per week",
            "teaching-hours-per-week"],
          ["Which academic year did you start teaching in further education in England?",
            "September 2023 to August 2024",
            "further-education-teaching-start-year"],
          ["Which subject areas do you teach?",
            "<p class=\"govuk-body\">Chemistry</p><p class=\"govuk-body\">Maths</p>",
            "subjects-taught"],
          ["Building and construction courses",
            "<p class=\"govuk-body\">Qualifications approved for funding at level 3 and below in the building and construction sector subject area</p>" \
            "<p class=\"govuk-body\">T Level in building services engineering for construction</p>" \
            "<p class=\"govuk-body\">T Level in onsite construction</p>" \
            "<p class=\"govuk-body\">T Level in design, surveying and planning for construction</p>" \
            "<p class=\"govuk-body\">Level 2 or level 3 apprenticeships in the construction and the built environment occupational route</p>",
            "building-construction-courses"],
          ["Chemistry courses",
            "<p class=\"govuk-body\">A or AS level chemistry</p>" \
            "<p class=\"govuk-body\">GCSE chemistry</p>" \
            "<p class=\"govuk-body\">IBO level 3 SL and HL chemistry, taught as part of a diploma or career related programme or as a standalone certificate</p>" \
            "<p class=\"govuk-body\">IBO level 1 / level 2 MYP chemistry</p>",
            "chemistry-courses"],
          ["Computing courses",
            "<p class=\"govuk-body\">Qualifications approved for funding at level 3 and below in the Digital technology (practitioners) sector subject area</p>" \
            "<p class=\"govuk-body\">Qualifications approved for funding at level 3 and below in the Digital technology for users sector subject area</p>" \
            "<p class=\"govuk-body\">Digital functional skills qualifications and essential digital skills qualifications</p>" \
            "<p class=\"govuk-body\">T Level in digital support services</p>" \
            "<p class=\"govuk-body\">T Level in digital business services</p>" \
            "<p class=\"govuk-body\">T Level in digital production, design and development</p>" \
            "<p class=\"govuk-body\">IBO level 3 SL and HL computer science, taught as part of a diploma or career related programme or as a standalone certificate</p>" \
            "<p class=\"govuk-body\">Level 2 or level 3 apprenticeships in the digital occupational route</p>",
            "computing-courses"],
          ["Early years courses",
            "<p class=\"govuk-body\">Early years practitioner (level 2) apprenticeship</p>" \
            "<p class=\"govuk-body\">Early years educator (level 3) apprenticeship</p>" \
            "<p class=\"govuk-body\">T Level in education and early years (early years educator)</p>" \
            "<p class=\"govuk-body\">Early years qualification approved for funding at level 3 and below which enables providers to count the recipient in staff:child ratios on 14 October 2024</p>",
            "early-years-courses"],
          ["Engineering and manufacturing courses",
            "<p class=\"govuk-body\">Qualifications approved for funding at level 3 and below in the engineering sector subject area</p>" \
            "<p class=\"govuk-body\">Qualifications approved for funding at level 3 and below in the manufacturing technologies sector subject area</p>" \
            "<p class=\"govuk-body\">Qualifications approved for funding at level 3 and below in the transportation operations and maintenance sector subject area</p>" \
            "<p class=\"govuk-body\">T Level in design and development for engineering and manufacturing</p>" \
            "<p class=\"govuk-body\">T Level in maintenance, installation and repair for engineering and manufacturing</p>" \
            "<p class=\"govuk-body\">T Level in engineering, manufacturing, processing and control</p>" \
            "<p class=\"govuk-body\">Level 2 or level 3 apprenticeships in the engineering and manufacturing occupational route</p>",
            "engineering-manufacturing-courses"],
          ["Maths courses",
            "<p class=\"govuk-body\">Qualifications approved for funding at level 3 and below in the mathematics and statistics sector subject area</p>" \
            "<p class=\"govuk-body\">GCSE in maths, functional skills qualifications and other maths qualifications approved for teaching to 16 to 19-year-olds who meet the condition of funding</p>",
            "maths-courses"],
          ["Physics courses",
            "<p class=\"govuk-body\">A or AS level physics</p>" \
            "<p class=\"govuk-body\">GCSE physics</p>" \
            "<p class=\"govuk-body\">IBO level 1 / level 2 MYP physics</p>" \
            "<p class=\"govuk-body\">IBO level 3 in SL and HL physics, taught as part of a diploma or career related programme or as a standalone certificate</p>",
            "physics-courses"],
          ["Do you spend at least half of your timetabled teaching hours teaching these eligible courses?",
            "Yes",
            "hours-teaching-eligible-subjects"],
          ["Are at least half of your timetabled teaching hours spent teaching 16 to 19-year-olds, including those up to age 25 with an Education, Health and Care Plan (EHCP)?",
            "Yes",
            "half-teaching-hours"],
          ["Do you have a teaching qualification?",
            "Yes",
            "teaching-qualification"],
          ["Are you subject to any formal performance measures as a result of continuous poor teaching standards?",
            "No",
            "poor-performance"],
          ["Are you currently subject to disciplinary action?",
            "No",
            "poor-performance"]
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

    context "courses" do
      context "course field has no answers" do
        let(:maths_courses) { [] }

        it do
          questions = subject.map { |question, answers, slug| question }

          expect(questions).to_not include("Maths courses")
        end
      end

      context "course field has none selected - still show none option" do
        let(:maths_courses) { ["none"] }

        it do
          questions = subject.map { |question, answers, slug| question }

          expect(questions).to include("Maths courses")
        end
      end
    end
  end
end
