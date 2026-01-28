require "rails_helper"

# These existing specs are too complicated, so using
# `spec/features/admin_edit_claim_spec.rb` for ECP
# and Targeted Retention Incentive instead. Keeping these here because they
# at least cover TSLR and Maths & Physics (which
# themselves are slightly different from ECP and Targeted Retention Incentive).
RSpec.feature "Admin amends a claim" do
  let(:claim) do
    create(
      :claim,
      :submitted,
      eligibility_attributes: {teacher_reference_number: "1234567"},
      payroll_gender: :dont_know,
      date_of_birth: date_of_birth,
      student_loan_plan: :plan_1,
      bank_sort_code: "010203",
      bank_account_number: "47274828",
      building_society_roll_number: "RN 123456",
      address_line_1: "Old address line 1",
      address_line_2: "Old address line 2",
      address_line_3: "Old address line 3",
      address_line_4: "Old address line 4",
      postcode: "AB12 3CD"
    )
  end
  let(:date_of_birth) { 25.years.ago.to_date }

  before do
    create(:journey_configuration, :student_loans)
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "Service operator amends a claim" do
    visit admin_claim_url(claim)

    click_on "Amend claim"

    new_date_of_birth = 30.years.ago.to_date

    fill_in "Teacher reference number", with: "7654321"
    fill_in "National insurance number", with: "YZ873206D"
    fill_in "Day", with: new_date_of_birth.day
    fill_in "Month", with: new_date_of_birth.month
    fill_in "Year", with: new_date_of_birth.year
    select "Plan 2", from: "Student loan repayment plan"
    fill_in "Bank sort code", with: "111213"
    fill_in "Bank account number", with: "18929492"

    fill_in "Address line 1", with: "New address line 1"
    fill_in "Address line 2", with: "New address line 2"
    fill_in "Address line 3", with: "New address line 3"
    fill_in "Address line 4", with: "New address line 4"
    fill_in "Postcode", with: "TE57 1NG"

    fill_in "Change notes", with: "This claimant got some of their details wrong and then contacted us"

    expect { click_on "Amend claim" }.to change { claim.reload.amendments.size }.by(1)

    amendment = claim.amendments.last
    expect(amendment.claim_changes).to eq({
      "teacher_reference_number" => ["1234567", "7654321"],
      "date_of_birth" => [date_of_birth, new_date_of_birth],
      "national_insurance_number" => ["AB100000C", "YZ873206D"],
      "student_loan_plan" => ["plan_1", "plan_2"],
      "bank_sort_code" => ["010203", "111213"],
      "bank_account_number" => ["47274828", "18929492"],
      "address_line_1" => ["Old address line 1", "New address line 1"],
      "address_line_2" => ["Old address line 2", "New address line 2"],
      "address_line_3" => ["Old address line 3", "New address line 3"],
      "address_line_4" => ["Old address line 4", "New address line 4"],
      "postcode" => ["AB12 3CD", "TE57 1NG"]
    })
    expect(amendment.notes).to eq("This claimant got some of their details wrong and then contacted us")
    expect(amendment.created_by).to eq(@signed_in_user)

    expect(claim.eligibility.reload.teacher_reference_number).to eq("7654321")
    expect(claim.date_of_birth).to eq(new_date_of_birth)
    expect(claim.student_loan_plan).to eq("plan_2")
    expect(claim.bank_sort_code).to eq("111213")
    expect(claim.bank_account_number).to eq("18929492")
    expect(claim.address_line_1).to eq("New address line 1")
    expect(claim.address_line_2).to eq("New address line 2")
    expect(claim.address_line_3).to eq("New address line 3")
    expect(claim.address_line_4).to eq("New address line 4")
    expect(claim.postcode).to eq("TE57 1NG")

    expect(current_url).to eq(admin_claim_tasks_url(claim))

    expect(page).to have_content("Claim has been amended successfully")

    click_on "Claim amendments"

    expect(page).to have_content("Teacher reference number\nchanged from 1234567 to 7654321")
    expect(page).to have_content("Date of birth\nchanged from #{I18n.l(date_of_birth)} to #{I18n.l(new_date_of_birth)}")
    expect(page).to have_content("Student loan repayment plan\nchanged from Plan 1 to Plan 2")
    expect(page).to have_content("Bank sort code\nchanged from 010203 to 111213")
    expect(page).to have_content("Bank account number\nchanged from 47274828 to 18929492")

    expect(page).to have_content("Address line 1\nchanged from Old address line 1 to New address line 1")
    expect(page).to have_content("Address line 2\nchanged from Old address line 2 to New address line 2")
    expect(page).to have_content("Address line 3\nchanged from Old address line 3 to New address line 3")
    expect(page).to have_content("Address line 4\nchanged from Old address line 4 to New address line 4")
    expect(page).to have_content("Postcode\nchanged from AB12 3CD to TE57 1NG")

    expect(page).to have_content("This claimant got some of their details wrong and then contacted us")
    expect(page).to have_content("by #{@signed_in_user.full_name} on #{I18n.l(Time.current)}")

    visit admin_claim_tasks_path(claim)
    click_link "Claim timeline"
    expect(page).to have_text("Claim amended")
  end

  scenario "Service operator cancels amending a claim" do
    visit admin_claim_url(claim)

    click_on "Amend claim"

    fill_in "Teacher reference number", with: "7654321"

    expect { click_on "Cancel" }.not_to change { [claim.reload.amendments.size, claim.eligibility.teacher_reference_number] }

    expect(current_url).to eq(admin_claim_tasks_url(claim))
  end

  # I would have written this as a request spec but there wasn’t an easy way
  # to do it because the message is split over various HTML tags.
  scenario "The amendments timeline can display an amendment that’s had its personal data removed" do
    create(:amendment, :personal_data_removed, claim: claim, claim_changes: {
      "teacher_reference_number" => ["7654321", "1234567"],
      "bank_account_number" => nil
    })

    visit admin_claim_amendments_url(claim)

    expect(page).to have_content("Teacher reference number\nchanged from 7654321 to 1234567")
    expect(page).to have_content("Bank account number\nchanged")
    expect(page).not_to have_content("Bank account number\nchanged from")
  end

  context "with a Student Loans claim" do
    let(:claim) do
      create(:claim, :submitted, eligibility: build(:student_loans_eligibility, :eligible, award_amount: 550))
    end

    scenario "Service operator amends the student loan repayment amount" do
      visit admin_claim_url(claim)

      click_on "Amend claim"

      fill_in "Student loan repayment amount", with: "300"
      fill_in "Change notes", with: "The claimant calculated the incorrect student loan repayment amount"
      expect { click_on "Amend claim" }.to change { claim.reload.amendments.size }.by(1)

      amendment = claim.amendments.last
      expect(amendment.claim_changes).to eq({
        "award_amount" => [550, 300]
      })
      expect(amendment.notes).to eq("The claimant calculated the incorrect student loan repayment amount")
      expect(amendment.created_by).to eq(@signed_in_user)

      expect(claim.eligibility.award_amount).to eq(300)

      click_on "Claim amendments"

      expect(page).to have_content("Award amount\nchanged from £550.00 to £300.00")

      expect(page).to have_content("The claimant calculated the incorrect student loan repayment amount")
      expect(page).to have_content("by #{@signed_in_user.full_name} on #{I18n.l(Time.current)}")
    end
  end

  context "with a submitted claim that would now fail validation on submit context" do
    let(:claim) { create(:claim, :submitted, policy: Policies::StudentLoans) }

    before do
      claim.eligibility.claim_school = create(:school, :student_loans_ineligible)
      claim.eligibility.save!
    end

    scenario "Service operator amends the claim" do
      visit admin_claim_url(claim)
      click_on "Amend claim"

      fill_in "Student loan repayment amount", with: "300"
      fill_in "Change notes", with: "The claimant calculated the incorrect student loan repayment amount"
      click_on "Amend claim"

      expect(page).not_to have_text "There is a problem"
      expect(page).to have_content("Claim has been amended successfully")
    end
  end

  context "when claim is no longer amendable" do
    let!(:payment) do
      create(
        :payment,
        claims: [claim]
      )
    end

    scenario "admin can view amendments" do
      visit admin_claim_url(claim)
      click_link "View tasks"
      click_on "Claim amendments"

      expect(page).to have_content "Claim amendments"
    end

    scenario "admin cannot make amendments" do
      visit admin_claim_url(claim)
      expect(page).not_to have_content "Amend claim"

      visit new_admin_claim_amendment_path(claim)
      expect(page).to have_content "This claim cannot be amended"
    end
  end
end

RSpec.feature "Admin amends a claim" do
  before do
    create(:journey_configuration, :student_loans)
  end

  context "when user has failed hmrc bank validation" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        hmrc_bank_validation_succeeded: false
      )
    end

    context "when back office user is an admin" do
      before do
        sign_in_as_service_admin
      end

      scenario "admin can view and edit account name" do
        visit admin_claim_url(claim)
        click_link "Amend claim"

        new_banking_name = "#{claim.banking_name}A"

        expect(page).to have_field("Banking name", with: claim.banking_name)
        fill_in "Banking name", with: new_banking_name
        fill_in "Change notes", with: "update banking name"
        click_button "Amend claim"

        click_link "Amend claim"

        expect(page).to have_field("Banking name", with: new_banking_name)
      end
    end

    context "back office user does does not have admin role" do
      before do
        sign_in_as_service_operator
      end

      scenario "admin can view but not edit account name" do
        visit admin_claim_url(claim)
        click_link "Amend claim"

        expect(page).to have_field("Banking name", with: claim.banking_name, disabled: true)
      end
    end
  end

  context "when user has passed hmrc bank validation" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        hmrc_bank_validation_succeeded: true
      )
    end

    context "when back office user is an admin" do
      before do
        sign_in_as_service_admin
      end

      scenario "admin cannot view or edit account name" do
        visit admin_claim_url(claim)
        click_link "Amend claim"

        expect(page).not_to have_field("Banking name", with: claim.banking_name)
      end
    end

    context "back office user does does not have admin role" do
      before do
        sign_in_as_service_operator
      end

      scenario "admin can view but not edit account name" do
        visit admin_claim_url(claim)
        click_link "Amend claim"

        expect(page).not_to have_field("Banking name", with: claim.banking_name)
      end
    end
  end

  context "when user has failed hmrc bank validation" do
    let(:claim) do
      create(
        :claim,
        :submitted,
        hmrc_bank_validation_succeeded: false
      )
    end

    context "when back office user is an admin" do
      before do
        sign_in_as_service_admin
      end

      scenario "admin can view and edit account name" do
        visit admin_claim_url(claim)
        click_link "Amend claim"

        new_banking_name = "#{claim.banking_name}A"

        expect(page).to have_field("Banking name", with: claim.banking_name)
        fill_in "Banking name", with: new_banking_name
        fill_in "Change notes", with: "update banking name"
        click_button "Amend claim"

        click_link "Amend claim"

        expect(page).to have_field("Banking name", with: new_banking_name)
      end
    end

    context "back office user does does not have admin role" do
      before do
        sign_in_as_service_operator
      end

      scenario "admin can view but not edit account name" do
        visit admin_claim_url(claim)
        click_link "Amend claim"

        expect(page).to have_field("Banking name", with: claim.banking_name, disabled: true)
      end
    end
  end
end
