require "rails_helper"

RSpec.describe "Targeted retention incentives ineligible paths" do
  include OmniauthMockHelper

  before { FeatureFlag.enable!(:tri_only_journey) }

  let!(:journey_configuration) do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments_only,
      teacher_id_enabled: true
    )
  end

  after do
    set_mock_auth(nil)
  end

  it "allows the user to change school if their school is ineligible" do
    ineligible_school = create(:school)

    eligible_school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue without signing in"

    # current-school
    fill_in "Which school do you teach at?", with: ineligible_school.name
    click_on "Continue"

    # current-school part 2
    choose ineligible_school.name
    click_on "Continue"

    expect(page).to have_content("The school you have selected is not eligible")

    click_on "Change school"

    # current-school
    fill_in "Which school do you teach at?", with: eligible_school.name
    click_on "Continue"

    # current-school part 2
    choose eligible_school.name
    click_on "Continue"

    # nqt-in-academic-year-after-itt
    expect(page).to have_content(
      "Are you currently teaching as a qualified teacher?"
    )
  end

  it "allows tid users to change school if their school is ineligible" do
    eligible_school = create(
      :school,
      :targeted_retention_incentive_payments_eligible
    )

    la = create(:local_authority)

    tps_record = create(
      :teachers_pensions_service,
      school_urn: 123456,
      teacher_reference_number: 1234567,
      end_date: 1.day.from_now,
      la_urn: la.code
    )

    ineligible_school = create(
      :school,
      establishment_number: tps_record.school_urn,
      local_authority: la
    )

    set_mock_auth("1234567")

    stub_qualified_teaching_statuses_show(
      trn: "1234567",
      params: {birthdate: "1940-01-01", nino: "AB123456C"}
    )

    visit Journeys::TargetedRetentionIncentivePayments.start_page_url

    click_on "Start now"

    # sign-in-or-continue
    click_on "Continue with DfE Identity"

    choose "Yes"
    click_on "Continue"

    # correct-school
    choose ineligible_school.name
    click_on "Continue"

    expect(page).to have_content("The school you have selected is not eligible")

    click_on "Change school"

    # current-school
    fill_in "Which school do you teach at?", with: eligible_school.name

    click_on "Continue"

    # current-school part 2
    choose eligible_school.name
    click_on "Continue"

    # nqt-in-academic-year-after-itt
    expect(page).to have_content(
      "Are you currently teaching as a qualified teacher?"
    )
  end

  context "when the claimant is a supply teacher" do
    it "is ineligible if they do not have a long term contract" do
      school = create(
        :school,
        :targeted_retention_incentive_payments_eligible
      )

      visit Journeys::TargetedRetentionIncentivePayments.start_page_url

      click_on "Start now"

      # sign-in-or-continue
      click_on "Continue without signing in"

      # current-school
      fill_in "Which school do you teach at?", with: school.name
      click_on "Continue"

      # current-school part 2
      choose school.name
      click_on "Continue"

      # nqt-in-academic-year-after-itt
      choose "Yes"
      click_on "Continue"

      # supply-teacher
      choose "Yes"
      click_on "Continue"

      # entire-term-contract
      choose "No"
      click_on "Continue"

      expect(page).to have_content(
        "You are not eligible for a school targeted retention incentive payment."
      )
    end

    it "is ineligible if they are not employed directly" do
      school = create(
        :school,
        :targeted_retention_incentive_payments_eligible
      )

      visit Journeys::TargetedRetentionIncentivePayments.start_page_url

      click_on "Start now"

      # sign-in-or-continue
      click_on "Continue without signing in"

      # current-school
      fill_in "Which school do you teach at?", with: school.name
      click_on "Continue"

      # current-school part 2
      choose school.name
      click_on "Continue"

      # nqt-in-academic-year-after-itt
      choose "Yes"
      click_on "Continue"

      # supply-teacher
      choose "Yes"
      click_on "Continue"

      # entire-term-contract
      choose "Yes"
      click_on "Continue"

      # employed-directly
      choose "No"
      click_on "Continue"

      expect(page).to have_content(
        "You are not eligible for a school targeted retention incentive payment"
      )
    end
  end

  context "when the claimant has poor performance" do
    it "is ineligible" do
      school = create(
        :school,
        :targeted_retention_incentive_payments_eligible
      )

      visit Journeys::TargetedRetentionIncentivePayments.start_page_url

      click_on "Start now"

      # sign-in-or-continue
      click_on "Continue without signing in"

      # current-school
      fill_in "Which school do you teach at?", with: school.name
      click_on "Continue"

      # current-school part 2
      choose school.name
      click_on "Continue"

      # nqt-in-academic-year-after-itt
      choose "Yes"
      click_on "Continue"

      # supply-teacher
      choose "No"
      click_on "Continue"

      # poor-performance
      all(".govuk-radios__label").select { it.text == "Yes" }.first.click

      all(".govuk-radios__label").select { it.text == "No" }.last.click

      click_on "Continue"

      expect(page).to have_content(
        "You are not eligible for a targeted retention incentive payment."
      )
    end
  end

  context "when the claimant has disciplinary measures" do
    it "is ineligible" do
      school = create(
        :school,
        :targeted_retention_incentive_payments_eligible
      )

      visit Journeys::TargetedRetentionIncentivePayments.start_page_url

      click_on "Start now"

      # sign-in-or-continue
      click_on "Continue without signing in"

      # current-school
      fill_in "Which school do you teach at?", with: school.name
      click_on "Continue"

      # current-school part 2
      choose school.name
      click_on "Continue"

      # nqt-in-academic-year-after-itt
      choose "Yes"
      click_on "Continue"

      # supply-teacher
      choose "No"
      click_on "Continue"

      # poor-performance
      all(".govuk-radios__label").select { it.text == "No" }.first.click

      all(".govuk-radios__label").select { it.text == "Yes" }.last.click

      click_on "Continue"

      expect(page).to have_content(
        "You are not eligible for a targeted retention incentive payment."
      )
    end
  end

  context "when itt year is outside of the policy range" do
    context "when the itt year came from dqt" do
      it "is ineligible" do
        # Presence of a matching TPS record triggers the slug sequence to show
        # the "correct-school"
        la = create(:local_authority)

        tps_record = create(
          :teachers_pensions_service,
          school_urn: 123456,
          teacher_reference_number: 1234567,
          end_date: 1.day.from_now,
          la_urn: la.code
        )

        create(
          :school,
          :targeted_retention_incentive_payments_eligible,
          name: "Springfield Elementary School",
          establishment_number: tps_record.school_urn,
          local_authority: la
        )

        set_mock_auth(
          "1234567",
          {
            date_of_birth: "1953-10-23",
            nino: "QQ123456C",
            given_name: "Seymour",
            family_name: "Skinner",
            email: "seymoure.skinner@springfield-elementary.edu",
            email_verified: true
          },
          phone_number: "07700900000"
        )

        # ITT year from DQT is outside of the policy range however this currently
        # gets set to AcademicYear.new by
        # `TargetedRetentionIncentivePayments::DqtRecord#itt_academic_year_for_claim`
        # so we end up showing them the itt year form
        stub_qualified_teaching_statuses_show(
          trn: "1234567",
          params: {birthdate: "1953-10-23", nino: "QQ123456C"},
          body: {
            qualified_teacher_status: {
              qts_date: "1990-07-01"
            },
            initial_teacher_training: {
              subject1: "physics",
              subject1_code: "F300"
            },
            qualifications: [
              {
                he_subject1_code: "F300"
              }
            ]
          }
        )

        visit Journeys::TargetedRetentionIncentivePayments.start_page_url

        click_on "Start now"

        # sign-in-or-continue
        click_on "Continue with DfE Identity"

        # confirm tid details
        choose "Yes"
        click_on "Continue"

        # correct-school
        choose "Springfield Elementary School"
        click_on "Continue"

        # nqt-in-academic-year-after-itt
        choose "Yes"
        click_on "Continue"

        # supply-teacher
        choose "No"
        click_on "Continue"

        # poor-performance
        all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
        click_on "Continue"

        # confirm qualification details
        choose "Yes"
        click_on "Continue"

        expect(page).to have_content(
          "You are not eligible for a school targeted retention incentive " \
          "payment because of the year you studied."
        )
      end
    end

    context "when the claimant selected none of the above as their itt year" do
      it "is ineligible" do
        school = create(
          :school,
          :targeted_retention_incentive_payments_eligible
        )

        visit Journeys::TargetedRetentionIncentivePayments.start_page_url

        click_on "Start now"

        # sign-in-or-continue
        click_on "Continue without signing in"

        # current-school
        fill_in "Which school do you teach at?", with: school.name
        click_on "Continue"

        # current-school part 2
        choose school.name
        click_on "Continue"

        # nqt-in-academic-year-after-itt
        choose "Yes"
        click_on "Continue"

        # supply-teacher
        choose "No"
        click_on "Continue"

        # poor-performance
        all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
        click_on "Continue"

        # qualification
        choose "Postgraduate initial teacher training (ITT)"
        click_on "Continue"

        # itt-year
        choose "None of the above"
        click_on "Continue"

        expect(page).to have_content(
          "You are not eligible for a school targeted retention incentive " \
          "payment because of the year you studied."
        )
      end
    end
  end

  context "when the claimant doesn't have an eligible itt subject or degree" do
    context "when the data came from DQT" do
      it "is ineligible" do
        school = create(
          :school,
          :targeted_retention_incentive_payments_eligible
        )

        set_mock_auth("1234567")

        itt_year = (AcademicYear.current - 1).start_of_autumn_term.iso8601

        # Return an ineligible subject and ineligible degree code
        stub_qualified_teaching_statuses_show(
          trn: "1234567",
          params: {birthdate: "1940-01-01", nino: "AB123456C"},
          body: {
            initial_teacher_training: {
              subject1: "crytpozoology"
            },
            qualified_teacher_status: {
              qts_date: itt_year
            },
            qualifications: [
              {
                he_subject1_code: "ineligible"
              }
            ]
          }
        )

        visit Journeys::TargetedRetentionIncentivePayments.start_page_url

        click_on "Start now"

        # sign-in-or-continue
        click_on "Continue with DfE Identity"

        # confirm tid details
        choose "Yes"
        click_on "Continue"

        # current-school
        fill_in "Which school do you teach at?", with: school.name
        click_on "Continue"

        # current-school part 2
        choose school.name
        click_on "Continue"

        # nqt-in-academic-year-after-itt
        choose "Yes"
        click_on "Continue"

        # supply-teacher
        choose "No"
        click_on "Continue"

        # poor-performance
        all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
        click_on "Continue"

        # confirm qualification details
        choose "Yes"
        click_on "Continue"

        expect(page).to have_content(
          "You are not eligible for the school targeted retention incentive " \
          "because of the subject you studied"
        )
      end
    end

    context "when the data came from the form" do
      it "is ineligible" do
        school = create(
          :school,
          :targeted_retention_incentive_payments_eligible
        )

        visit Journeys::TargetedRetentionIncentivePayments.start_page_url

        click_on "Start now"

        # sign-in-or-continue
        click_on "Continue without signing in"

        # current-school
        fill_in "Which school do you teach at?", with: school.name
        click_on "Continue"

        # current-school part 2
        choose school.name
        click_on "Continue"

        # nqt-in-academic-year-after-itt
        choose "Yes"
        click_on "Continue"

        # supply-teacher
        choose "No"
        click_on "Continue"

        # poor-performance
        all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
        click_on "Continue"

        # qualification
        choose "Postgraduate initial teacher training (ITT)"
        click_on "Continue"

        # itt-year
        itt_year = (AcademicYear.current - 1).to_s(:long)
        choose itt_year
        click_on "Continue"

        # eligible-itt-subject
        choose "None of the above"
        click_on "Continue"

        # eligible-degree-subject
        choose "No"
        click_on "Continue"

        expect(page).to have_content(
          "You are not eligible for the school targeted retention incentive " \
          "because of the subject you studied"
        )

        expect(page).to have_content(
          "To be eligible, you must have completed your initial teacher training " \
          "(ITT), undergraduate or postgraduate degree in chemistry, computing, " \
          "mathematics, or physics"
        )
      end
    end
  end

  context "when a trainee teacher in the last policy year" do
    it "is ineligible" do
      # Complete the wizard in the last policy year
      journey_configuration.update!(
        current_academic_year: Policies::TargetedRetentionIncentivePayments::POLICY_END_YEAR
      )

      school = create(
        :school,
        :targeted_retention_incentive_payments_eligible
      )

      visit Journeys::TargetedRetentionIncentivePayments.start_page_url

      click_on "Start now"

      # sign-in-or-continue
      click_on "Continue without signing in"

      # current-school
      fill_in "Which school do you teach at?", with: school.name
      click_on "Continue"

      # current-school part 2
      choose school.name
      click_on "Continue"

      # nqt-in-academic-year-after-itt - select No (trainee teacher)
      choose "No, I’m a trainee teacher"
      click_on "Continue"

      expect(page).to have_content("You are not eligible")

      # See TargetedRetentionIncentivePayments POLICY_START_YEAR and
      # POLICY_END_YEAR for where the dates come form.
      expect(page).to have_content(
        "You do not qualify for a targeted retention incentive payment this " \
        "year because you have not completed your initial teacher training."
      )
    end
  end

  context "when the claimant doesn't teach enough hours" do
    it "is ineligible" do
      school = create(
        :school,
        :targeted_retention_incentive_payments_eligible
      )

      visit Journeys::TargetedRetentionIncentivePayments.start_page_url

      click_on "Start now"

      # sign-in-or-continue
      click_on "Continue without signing in"

      # current-school
      fill_in "Which school do you teach at?", with: school.name
      click_on "Continue"

      # current-school part 2
      choose school.name
      click_on "Continue"

      # nqt-in-academic-year-after-itt
      choose "Yes"
      click_on "Continue"

      # supply-teacher
      choose "No"
      click_on "Continue"

      # poor-performance
      all(".govuk-radios__label").select { it.text == "No" }.each(&:click)
      click_on "Continue"

      # qualification
      choose "Postgraduate initial teacher training (ITT)"
      click_on "Continue"

      # itt-year
      choose "2023 to 2024"
      click_on "Continue"

      # eligible-itt-subject
      choose "Physics"
      click_on "Continue"

      # teaching-subject-now
      choose "No"
      click_on "Continue"

      expect(page).to have_content(
        "You are not eligible for a targeted retention incentive payment " \
        "because you do not spend at least half of your contracted hours " \
        "teaching eligible subjects."
      )
    end
  end
end
