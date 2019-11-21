require "rails_helper"

RSpec.feature "A user can switch policies" do
  it "a user can switch to maths and physics after starting a student loan claim" do
    start_student_loans_claim
    visit new_claim_path(MathsAndPhysics.routing_name)

    expect(page).to have_text(I18n.t("maths_and_physics.questions.teaching_maths_or_physics"))
  end

  it "a user can switch to student loans after starting a maths and physics claim" do
    start_maths_and_physics_claim
    visit new_claim_path(StudentLoans.routing_name)

    expect(page).to have_text(I18n.t("questions.qts_award_year"))
  end
end
