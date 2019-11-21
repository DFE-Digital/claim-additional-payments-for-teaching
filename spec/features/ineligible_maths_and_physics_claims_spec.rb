require "rails_helper"

RSpec.feature "Ineligible Maths and Physics claims" do
  scenario "not teaching maths or physics" do
    visit new_claim_path(MathsAndPhysics.routing_name)
    choose "No"
    click_on "Continue"
    claim = Claim.order(:created_at).last

    expect(claim.eligibility.teaching_maths_or_physics).to eql false
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you teach maths or physics.")
  end

  scenario "chooses an ineligible current school" do
    claim = start_maths_and_physics_claim

    choose_school schools(:hampstead_school)

    expect(claim.eligibility.reload.current_school).to eq schools(:hampstead_school)
    expect(page).to have_text("This school is not eligible")
    expect(page).to have_text("You can only get this payment if you are employed to teach at an eligible state-funded secondary school.")
  end

  scenario "chooses no degree in maths or physics" do
    claim = start_maths_and_physics_claim

    choose_school schools(:penistone_grammar_school)
    choose_initial_teacher_training_specialised_in_maths_or_physics("No")
    choose_maths_and_physics_degree("No")

    expect(claim.eligibility.reload.has_uk_maths_or_physics_degree).to eq "no"
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you completed a degree specialising in maths or physics")
  end

  scenario "qualified before the first eligible year" do
    claim = start_maths_and_physics_claim

    choose_school schools(:penistone_grammar_school)
    choose_initial_teacher_training_specialised_in_maths_or_physics("Yes")
    choose_qts_year("Before 1 September 2014")

    expect(claim.eligibility.reload.qts_award_year).to eql("before_september_2014")
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you completed your initial teacher training on or after 1 September 2014.")
  end

  scenario "supply teacher doesn't have a contract for a whole term" do
    claim = start_maths_and_physics_claim

    choose_school schools(:penistone_grammar_school)
    choose_initial_teacher_training_specialised_in_maths_or_physics("Yes")
    choose_qts_year("On or after 1 September 2014")

    choose "Yes"
    click_on "Continue"
    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.has_entire_term_contract).to eql false
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you are employed directly by your school for at least one term")
  end

  scenario "supply teacher isn't employed directly by school" do
    claim = start_maths_and_physics_claim

    choose_school schools(:penistone_grammar_school)
    choose_initial_teacher_training_specialised_in_maths_or_physics("Yes")
    choose_qts_year("On or after 1 September 2014")

    choose "Yes"
    click_on "Continue"
    choose "Yes"
    click_on "Continue"
    choose "No, I’m employed by a private agency"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_directly).to eql false
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you are employed directly by the school.")
  end

  scenario "subject to disciplinary action" do
    claim = start_maths_and_physics_claim

    choose_school schools(:penistone_grammar_school)
    choose_initial_teacher_training_specialised_in_maths_or_physics("Yes")
    choose_qts_year("On or after 1 September 2014")

    choose "No"
    click_on "Continue"
    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql true
    expect(page).to have_text("You’re not eligible")
    expect(page).to have_text("You can only get this payment if you’re not currently subject to disciplinary action.")
  end
end
