require "rails_helper"

RSpec.feature "Teacher verifies identity using GOV.UK Verify" do
  scenario "successful verification" do
    claim = start_tslr_claim
    choose_qts_year
    choose_school schools(:penistone_grammar_school)
    choose_still_teaching
    choose_subjects_taught

    expect(page).to have_text("You are eligible to claim back student loan repayments")

    click_on "Continue to GOV.UK Verify"
    click_on "Complete STUBBED TEST GOV.UK Verify"

    expect(page).to have_text(I18n.t("tslr.questions.teacher_reference_number"))

    claim.reload
    expect(claim.full_name).to eql("Isambard Kingdom Brunel")
    expect(claim.address_line_1).to eq("Verified Street")
    expect(claim.address_line_2).to eq("Verified Town")
    expect(claim.address_line_3).to eq("Verified County")
    expect(claim.postcode).to eq("M12 345")
    expect(claim.date_of_birth).to eq(Date.new(1806, 4, 9))
  end
end
