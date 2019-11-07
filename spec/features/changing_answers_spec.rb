require "rails_helper"

RSpec.feature "Changing the answers on a submittable claim" do
  let(:claim) { Claim.order(:created_at).last }
  let(:eligibility) { claim.eligibility }

  before do
    answer_all_student_loans_claim_questions
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

  scenario "Teacher changes their year" do
    find("a[href='#{claim_path("qts-year")}']").click

    expect(find("#claim_eligibility_attributes_qts_award_year_on_or_after_september_2013").checked?).to eq(true)

    choose I18n.t("student_loans.questions.qts_award_years.on_or_after_september_2013")
    click_on "Continue"

    expect(eligibility.reload.qts_award_year).to eq("on_or_after_september_2013")

    expect(current_path).to eq(claim_path("check-your-answers"))
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
        uncheck I18n.t("student_loans.questions.eligible_subjects.physics_taught"), visible: false

        check I18n.t("student_loans.questions.eligible_subjects.biology_taught"), visible: false
        check I18n.t("student_loans.questions.eligible_subjects.chemistry_taught"), visible: false

        click_on "Continue"
      end

      scenario "Eligible subjects are set correctly" do
        expect(eligibility.reload.physics_taught).to eq(false)
        expect(eligibility.biology_taught).to eq(true)
        expect(eligibility.chemistry_taught).to eq(true)
      end

      scenario "Teacher is redirected to the check your answers page" do
        expect(current_path).to eq(claim_path("check-your-answers"))
      end
    end
  end

  context "when changing whether they had a leadership position" do
    context "when changing their answer to no" do
      before do
        claim.eligibility.had_leadership_position = true
        claim.save!

        find("a[href='#{claim_path("leadership-position")}']").click

        choose "No"
        click_on "Continue"
      end

      scenario "Sets had leadership position correctly" do
        expect(eligibility.reload.had_leadership_position).to eq(false)
      end

      scenario "Sets mostly performed leadership duties correctly" do
        expect(eligibility.reload.mostly_performed_leadership_duties).to eq(nil)
      end

      scenario "Teacher is redirected to the check your answers page" do
        expect(current_path).to eq(claim_path("check-your-answers"))
      end
    end

    context "when changing their answer to yes" do
      before do
        claim.eligibility.had_leadership_position = false
        claim.save!

        find("a[href='#{claim_path("leadership-position")}']").click

        choose "Yes"
        click_on "Continue"
      end

      scenario "Sets had leadership position correctly" do
        expect(eligibility.reload.had_leadership_position).to eq(true)
      end

      scenario "Sets mostly performed leadership duties correctly" do
        expect(eligibility.reload.mostly_performed_leadership_duties).to eq(nil)
      end

      scenario "Teacher is redirected to ask if they were mostly performing leadership duties" do
        expect(current_path).to eq(claim_path("mostly-performed-leadership-duties"))
      end

      context "Teacher spent less than half their time performing leadership duties" do
        before do
          choose "No"
          click_on "Continue"
        end

        scenario "Sets mostly performed leadership duties correctly" do
          expect(eligibility.reload.mostly_performed_leadership_duties).to eq(false)
        end

        scenario "Teacher is redirected to the check your answers page" do
          expect(current_path).to eq(claim_path("check-your-answers"))
        end
      end

      context "Teacher spent more than half their time performing leadership duties" do
        before do
          choose "Yes"
          click_on "Continue"
        end

        scenario "Sets mostly performed leadership duties correctly" do
          expect(eligibility.reload.mostly_performed_leadership_duties).to eq(true)
        end

        scenario "Teacher is told they are not eligible" do
          expect(page).to have_text("You’re not eligible")
          expect(page).to have_text("You can only get this payment if you spent less than half your working hours performing leadership duties between 6 April 2018 and 5 April 2019.")
        end
      end
    end
  end

  context "When changing claim school" do
    let!(:new_claim_school) { create(:school, :student_loan_eligible, name: "Claim School") }

    before do
      find("a[href='#{claim_path("claim-school")}']").click
    end

    scenario "Teacher sees their original claim school" do
      expect(find("input[name='school_search']").value).to eq(eligibility.claim_school_name)
    end

    context "When choosing a new claim school" do
      before do
        choose_school new_claim_school
      end

      scenario "school is changed correctly" do
        expect(eligibility.reload.claim_school).to eql new_claim_school
      end

      scenario "Teacher is redirected to the subjects taught screen" do
        expect(current_path).to eq(claim_path("subjects-taught"))
      end

      context "When still teaching eligible subjects" do
        before do
          check I18n.t("student_loans.questions.eligible_subjects.biology_taught"), visible: false
          check I18n.t("student_loans.questions.eligible_subjects.chemistry_taught"), visible: false

          click_on "Continue"
        end

        scenario "Eligible subjects are set correctly" do
          expect(eligibility.reload.biology_taught).to eq(true)
          expect(eligibility.chemistry_taught).to eq(true)
        end

        scenario "Teacher is redirected to the are you still employed screen" do
          expect(current_path).to eq(claim_path("still-teaching"))
        end

        context "When still teaching at the claim school" do
          before do
            choose "Yes, at Claim School"
            click_on "Continue"
          end

          scenario "current school is set correctly" do
            expect(eligibility.reload.employment_status).to eql("claim_school")
            expect(eligibility.current_school).to eql new_claim_school
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
            expect(eligibility.reload.employment_status).to eql("different_school")
            expect(eligibility.reload.current_school).to eql schools(:hampstead_school)
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
            expect(eligibility.reload.employment_status).to eq("no_school")
          end

          scenario "Teacher is told they are not eligible" do
            expect(page).to have_text("You’re not eligible")
            expect(page).to have_text("You can only get this payment if you’re still employed at a school.")
          end
        end
      end
    end
  end

  scenario "changing the are you still employed question (employment_status)" do
    find("a[href='#{claim_path("still-teaching")}']").click

    choose "Yes, at Penistone Grammar School"
    click_on "Continue"

    expect(current_path).to eq(claim_path("check-your-answers"))
    expect(eligibility.reload.employment_status).to eq("claim_school")
    expect(eligibility.current_school).to eq(schools(:penistone_grammar_school))
  end

  scenario "going from same school to different school" do
    eligibility.update!(employment_status: "claim_school")

    find("a[href='#{claim_path("still-teaching")}']").click

    choose "Yes, at another school"
    click_on "Continue"

    fill_in :school_search, with: "Hampstead"
    click_on "Search"

    choose "Hampstead School"
    click_on "Continue"
    expect(current_path).to eq(claim_path("check-your-answers"))
    expect(eligibility.reload.employment_status).to eq("different_school")
    expect(eligibility.current_school).to eq(schools(:hampstead_school))
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
    expect(claim.student_loan_plan).to eq Claim::NO_STUDENT_LOAN
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
    expect(claim.student_loan_country).to eq StudentLoan::WALES
    expect(claim.student_loan_courses).to eq "one_course"
    expect(claim.student_loan_start_date).to eq StudentLoan::BEFORE_1_SEPT_2012
    expect(claim.student_loan_plan).to eq StudentLoan::PLAN_1
  end

  scenario "user cannot change the value of an identity field that was acquired from Verify" do
    claim.update!(verified_fields: ["payroll_gender"])
    visit claim_path("check-your-answers")

    expect(page).to_not have_content(I18n.t("questions.payroll_gender"))
    expect(page).to_not have_selector(:css, "a[href='#{claim_path("gender")}']")

    expect {
      visit claim_path("gender")
    }.to raise_error(ActionController::RoutingError)
  end

  scenario "user can change the answer to an identity question that wasn't acquired from Verify" do
    claim.update!(verified_fields: [])
    visit claim_path("check-your-answers")

    expect(page).to have_content(I18n.t("questions.payroll_gender"))
    expect(page).to have_selector(:css, "a[href='#{claim_path("gender")}']")

    find("a[href='#{claim_path("gender")}']").click
    choose "I don't know"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("dont_know")
  end

  context "when changing the student loan repayment amount" do
    scenario "user can change answer and it preserves two decimal places" do
      claim.eligibility.update!(student_loan_repayment_amount: 100.1)
      visit claim_path("check-your-answers")

      expect(page).to have_content("£100.10")
      find("a[href='#{claim_path("student-loan-amount")}']").click

      expect(find("#claim_eligibility_attributes_student_loan_repayment_amount").value).to eq("100.10")
      fill_in I18n.t("student_loans.questions.student_loan_amount", claim_school_name: claim.eligibility.claim_school_name), with: "150.20"
      click_on "Continue"

      expect(page).to have_content("£150.20")
    end
  end
end
