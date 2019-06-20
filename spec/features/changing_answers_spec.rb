require "rails_helper"

RSpec.feature "Changing the answers on a submittable claim" do
  let(:claim_school) { create(:school, :tslr_eligible, name: "Claim School") }
  let(:current_school) { create(:school, :tslr_eligible, name: "Current School") }

  let(:claim) do
    create(:tslr_claim,
      :eligible_and_submittable,
      employment_status: :different_school,
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

  scenario "Teacher sees their original current school when editing" do
    find("a[href='#{claim_path("current-school")}']").click

    expect(find("input[name='school_search']").value).to eq(current_school.name)
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
          expect(page).to have_text("You must be still working as a teacher to be eligible")
        end
      end
    end
  end
end
