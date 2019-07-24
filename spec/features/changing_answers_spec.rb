require "rails_helper"

RSpec.feature "Changing the answers on a submittable claim" do
  let(:claim_school) { create(:school, :tslr_eligible, name: "Claim School") }
  let(:current_school) { create(:school, :tslr_eligible, name: "Current School") }

  let(:claim) do
    create(:tslr_claim,
      :submittable,
      employment_status: :different_school,
      physics_taught: true,
      claim_school: claim_school,
      current_school: current_school)
  end

  before do
    allow_any_instance_of(ClaimsController).to receive(:current_claim) { claim }
    visit claim_path("check-your-answers")
  end

  scenario "Teacher can edit a field" do
    old_number = claim.national_insurance_number
    new_number = "AB123456C"

    expect {
      find("a[href='#{claim_path("national-insurance-number")}']").click
      fill_in "National Insurance number", with: new_number
      click_on "Continue"
    }.to change {
      claim.reload.national_insurance_number
    }.from(old_number).to(new_number)

    expect(page).to have_content("Check your answers before sending your application")
  end

  context "when changing subjects taught" do
    before do
      find("a[href='#{claim_path("subjects-taught")}']").click
    end

    scenario "Teacher sees their original choices" do
      expect(find("#eligible_subjects_physics_taught").checked?).to eq(true)
    end

    context "Teacher changes their subjects" do
      before do
        uncheck I18n.t("tslr.questions.eligible_subjects.physics_taught"), visible: false

        check I18n.t("tslr.questions.eligible_subjects.biology_taught"), visible: false
        check I18n.t("tslr.questions.eligible_subjects.chemistry_taught"), visible: false

        click_on "Continue"
      end

      scenario "Eligible subjects are set correctly" do
        expect(claim.reload.physics_taught).to eq(false)
        expect(claim.reload.biology_taught).to eq(true)
        expect(claim.reload.chemistry_taught).to eq(true)
      end

      scenario "Teacher is redirected to ask if they were mostly teaching eligible subjects" do
        expect(current_path).to eq(claim_path("mostly-teaching-eligible-subjects"))
      end

      scenario "Teacher sees the the correct subjects in the question" do
        expect(page).to have_text("Biology and Chemistry")
      end

      context "Teacher taught subjects for more than 50% of their time" do
        before do
          choose "Yes"

          click_on "Continue"
        end

        scenario "Sets mostly teaching elibile subjects correctly" do
          expect(claim.reload.mostly_teaching_eligible_subjects).to eq(true)
        end

        scenario "Teacher is redirected to the check your answers page" do
          expect(current_path).to eq(claim_path("check-your-answers"))
        end
      end

      context "Teacher taught subjects for less than 50% of their time" do
        before do
          choose "No"

          click_on "Continue"
        end

        scenario "Sets mostly teaching elibile subjects correctly" do
          expect(claim.reload.mostly_teaching_eligible_subjects).to eq(false)
        end

        scenario "Teacher is told they are not eligible" do
          expect(page).to have_text("You’re not eligible")
          expect(page).to have_text("You must have spent at least half your time teaching an eligible subject")
        end
      end
    end
  end

  context "When changing claim school" do
    before do
      find("a[href='#{claim_path("claim-school")}']").click
    end

    scenario "Teacher sees their original claim school" do
      expect(find("input[name='school_search']").value).to eq(claim.claim_school.name)
    end

    context "When choosing a new claim school" do
      before do
        choose_school schools(:penistone_grammar_school)
      end

      scenario "school is changed correctly" do
        expect(claim.reload.claim_school).to eql schools(:penistone_grammar_school)
      end

      scenario "Teacher is redirected to the are you still employed screen" do
        expect(current_path).to eq(claim_path("still-teaching"))
      end

      context "When still teaching at the claim school" do
        before do
          choose_still_teaching
        end

        scenario "current school is set correctly" do
          expect(claim.reload.employment_status).to eql("claim_school")
          expect(claim.reload.current_school).to eql schools(:penistone_grammar_school)
        end

        scenario "Teacher is redirected to the check your answers page" do
          expect(current_path).to eq(claim_path("check-your-answers"))
        end
      end

      context "When still teaching but at a different school" do
        before do
          choose_still_teaching "Yes, at another school"

          fill_in :school_search, with: "Hampstead"
          click_on "Search"

          choose "Hampstead School"
          click_on "Continue"
        end

        scenario "School and employment status are set correctly" do
          expect(claim.reload.employment_status).to eql("different_school")
          expect(claim.reload.current_school).to eql schools(:hampstead_school)
        end

        scenario "Teacher is redirected to the check your answers page" do
          expect(current_path).to eq(claim_path("check-your-answers"))
        end
      end

      context "When no longer teaching" do
        before do
          choose_still_teaching "No"
        end

        scenario "Employment status is set correctly" do
          expect(claim.reload.employment_status).to eq("no_school")
        end

        scenario "Teacher is told they are not eligible" do
          expect(page).to have_text("You’re not eligible")
          expect(page).to have_text("You can only get this payment if you’re still working as a teacher")
        end
      end
    end
  end

  scenario "changing the are you still employed question (employment_status)" do
    find("a[href='#{claim_path("still-teaching")}']").click

    choose "Yes, at Claim School"
    click_on "Continue"

    expect(current_path).to eq(claim_path("check-your-answers"))
    expect(claim.reload.employment_status).to eq("claim_school")
    expect(claim.current_school).to eq(claim_school)
  end

  scenario "going from same school to different school" do
    claim.update!(employment_status: "claim_school")

    find("a[href='#{claim_path("still-teaching")}']").click

    choose "Yes, at another school"
    click_on "Continue"

    fill_in :school_search, with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"
    expect(current_path).to eq(claim_path("check-your-answers"))
    expect(claim.reload.employment_status).to eq("different_school")
    expect(claim.current_school).to eq(schools(:hampstead_school))
  end

  scenario "changing student loan answer to “No” resets the other student loan-related answers" do
    visit claim_path("check-your-answers")

    find("a[href='#{claim_path("student-loan")}']").click

    choose "No"
    click_on "Continue"

    expect(current_path).to eq(claim_path("check-your-answers"))
    expect(claim.reload.has_student_loan).to eq false
    expect(claim.student_loan_country).to be_nil
    expect(claim.student_loan_courses).to be_nil
    expect(claim.student_loan_start_date).to be_nil
    expect(claim.student_loan_plan).to eq TslrClaim::NO_STUDENT_LOAN
  end

  scenario "changing student loan country forces dependent questions to be re-answered" do
    visit claim_path("check-your-answers")

    find("a[href='#{claim_path("student-loan-country")}']").click

    choose "Wales"
    click_on "Continue"

    choose "1"
    click_on "Continue"

    choose "Before 1 September 2012"
    click_on "Continue"

    expect(current_path).to eq(claim_path("check-your-answers"))
    expect(claim.reload.has_student_loan).to eq true
    expect(claim.student_loan_country).to eq StudentLoans::WALES
    expect(claim.student_loan_courses).to eq "one_course"
    expect(claim.student_loan_start_date).to eq StudentLoans::BEFORE_1_SEPT_2012
    expect(claim.student_loan_plan).to eq StudentLoans::PLAN_1
  end
end
