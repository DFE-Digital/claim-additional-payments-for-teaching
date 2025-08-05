require "rails_helper"

RSpec.feature "Admin views claim details for FurtherEducationPayments" do
  before do
    create(:journey_configuration, :further_education_payments)
  end

  context "with a fixed contract" do
    it "shows the full claim details" do
      school = create(
        :school,
        :further_education,
        :fe_eligible,
        name: "Springfield Elementary"
      )

      eligibility = create(
        :further_education_payments_eligibility,
        school: school,
        teacher_reference_number: nil,
        teaching_responsibilities: true,
        contract_type: "permanent",
        fixed_term_full_year: true,
        teaching_hours_per_week: "more_than_12",
        further_education_teaching_start_year: "2023",
        subjects_taught: ["maths", "computing"],
        maths_courses: ["approved_level_321_maths", "gcse_maths"],
        computing_courses: ["level3_and_below_ict_for_practitioners"],
        hours_teaching_eligible_subjects: true,
        half_teaching_hours: true,
        teaching_qualification: "yes",
        subject_to_formal_performance_action: false,
        subject_to_disciplinary_action: false,
        award_amount: 6_000
      )

      claim = create(
        :claim,
        :further_education,
        eligibility:,
        first_name: "Edna",
        surname: "Krabappel",
        date_of_birth: Date.new(1945, 7, 3),
        reference: "AB123456",
        national_insurance_number: "QQ123456C",
        address_line_1: "82 Evergreen Terrace",
        address_line_2: "Springfield",
        address_line_4: "Oregon",
        postcode: "AB12 3CD",
        email_address: "edna.krabappel@springfield-elementary.edu",
        started_at: DateTime.new(2024, 8, 1, 9, 0, 0),
        submitted_at: DateTime.new(2024, 8, 1, 11, 0, 0),
        academic_year: AcademicYear.new(2024)
      )

      sign_in_as_service_operator

      visit admin_claim_path(claim)

      expect(summary_row("Teacher reference number")).to have_content(
        "Not provided"
      )

      expect(summary_row("Full name")).to have_content("Edna Krabappel")

      expect(summary_row("Date of birth")).to have_content("3 July 1945")

      expect(summary_row("National Insurance number")).to have_content(
        "QQ123456C"
      )

      expect(summary_row("Address")).to have_content("82 Evergreen Terrace")
      expect(summary_row("Address")).to have_content("Springfield")
      expect(summary_row("Address")).to have_content("Oregon")
      expect(summary_row("Address")).to have_content("AB12 3CD")

      expect(summary_row("Email address")).to have_content(
        "edna.krabappel@springfield-elementary.edu"
      )

      expect(
        summary_row("Are you a member of staff with teaching responsibilities?")
      ).to have_content("Yes")

      expect(
        summary_row("Which FE provider directly employs you?")
      ).to have_content("Springfield Elementary")

      expect(
        summary_row(
          "What type of contract do you have with Springfield Elementary?"
        )
      ).to have_content(
        "Permanent contract (including full-time and part-time contracts)"
      )

      expect(page).not_to have_content(
        "Does your fixed-term contract cover the full 2024 to 2025 academic year?"
      )

      expect(
        summary_row(
          "On average, how many hours per week are you timetabled to teach at " \
          "Springfield Elementary during the current term?"
        )
      ).to have_content("12 hours or more per week")

      expect(
        summary_row(
          "Which academic year did you start teaching in " \
          "further education in England?"
        )
      ).to have_content("September 2023 to August 2024")

      expect(summary_row("Which subject areas do you teach?")).to have_content(
        "Maths"
      )

      expect(summary_row("Which subject areas do you teach?")).to have_content(
        "Computing, including digital and ICT"
      )

      expect(summary_row("Maths courses")).to have_content(
        "Qualifications approved for funding at level 3 and below"
      )

      expect(summary_row("Maths courses")).to have_content(
        "GCSE in maths, functional skills qualifications"
      )

      expect(summary_row("Computing courses")).to have_content(
        "Qualifications approved for funding at level 3 and below"
      )

      expect(
        summary_row(
          "Do you spend at least half of your timetabled teaching hours " \
          "teaching these eligible courses?"
        )
      ).to have_content("Yes")

      expect(
        summary_row(
          "Are at least half of your timetabled teaching hours spent teaching " \
          "16 to 19-year-olds, including those up to age 25 with an Education, " \
          "Health and Care Plan (EHCP)?"
        )
      ).to have_content("Yes")

      expect(summary_row("Do you have a teaching qualification?")).to(
        have_content("Yes")
      )

      expect(
        summary_row(
          "Are you subject to any formal performance measures as a result of " \
          "continuous poor teaching standards?"
        )
      ).to have_content("No")

      expect(
        summary_row("Are you currently subject to disciplinary action?")
      ).to have_content("No")

      expect(
        summary_row("Further Education Targeted Retention Incentive")
      ).to have_content("£6,000")

      expect(summary_row("Started at")).to have_content("1 August 2024 10:00am")

      expect(summary_row("Submitted at")).to have_content("1 August 2024 12:00pm")

      expect(summary_row("Decision deadline")).to have_content("24 October 2024")
    end
  end
end
