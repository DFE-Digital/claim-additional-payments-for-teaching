require "rails_helper"

RSpec.feature "Admin claim allocation and deallocation" do
  let!(:admin_user) { sign_in_as_service_operator }

  let!(:second_admin) do
    create(
      :dfe_signin_user,
      :service_operator,
      :with_random_name
    )
  end
  let!(:third_admin) do
    create(
      :dfe_signin_user,
      :service_operator,
      :with_random_name
    )
  end

  let(:claim) { create(:claim, :submitted, assigned_to: assignee) }

  context "when claim is not assigned" do
    let(:assignee) { nil }

    scenario "then I can assign the claim to myself" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "This claim is currently unassigned"
      click_link "Assign claim"

      expect(page).to have_text "Who would you like to assign this claim to?"
      choose "Myself"
      click_button "Save changes"

      expect(page.current_path).to eql "/admin/claims/#{claim.id}/tasks"
      expect(page).to have_text "You are currently assigned this claim"
    end

    scenario "then I can assign the claim to someone else" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "This claim is currently unassigned"
      click_link "Assign claim"

      expect(page).to have_text "Who would you like to assign this claim to?"
      choose "A colleague"
      select second_admin.full_name
      click_button "Save changes"

      expect(page.current_path).to eql "/admin/claims/#{claim.id}/tasks"
      expect(page).to have_text "This claim is currently assigned to #{second_admin.full_name}"
    end

    scenario "it cannot be unassigned as already unassigned" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "This claim is currently unassigned"
      click_link "Assign claim"

      expect(page).to have_text "Who would you like to assign this claim to?"
      expect(page).not_to have_text "Unassign"
    end
  end

  context "when claim is assigned to me" do
    let(:assignee) { admin_user }

    scenario "then I can unassign the claim" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "You are currently assigned this claim"
      click_link "Assign claim"

      expect(page).to have_text "Who would you like to assign this claim to?"
      choose "Unassign"
      click_button "Save changes"

      expect(page.current_path).to eql "/admin/claims/#{claim.id}/tasks"
      expect(page).to have_text "This claim is currently unassigned"
    end

    scenario "then I can assign the claim to someone else" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "You are currently assigned this claim"
      click_link "Assign claim"

      expect(page).to have_text "Who would you like to assign this claim to?"
      choose "A colleague"
      select second_admin.full_name
      click_button "Save changes"

      expect(page.current_path).to eql "/admin/claims/#{claim.id}/tasks"
      expect(page).to have_text "This claim is currently assigned to #{second_admin.full_name}"
    end

    scenario "then i cannot assign to myself again" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "You are currently assigned this claim"
      click_link "Assign claim"

      expect(page).to have_text "Who would you like to assign this claim to?"
      expect(page).not_to have_text "Myself"
    end
  end

  context "when claim is assigned to someone else" do
    let(:assignee) { second_admin }

    scenario "then I can unassign the claim" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "This claim is currently assigned to #{second_admin.full_name}"
      click_link "Assign claim"

      expect(page).to have_text "Who would you like to assign this claim to?"
      choose "Unassign"
      click_button "Save changes"

      expect(page.current_path).to eql "/admin/claims/#{claim.id}/tasks"
      expect(page).to have_text "This claim is currently unassigned"
    end

    scenario "then I can assign the claim to myself" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "This claim is currently assigned to #{second_admin.full_name}"
      click_link "Assign claim"

      expect(page).to have_text "Who would you like to assign this claim to?"
      choose "Myself"
      click_button "Save changes"

      expect(page.current_path).to eql "/admin/claims/#{claim.id}/tasks"
      expect(page).to have_text "You are currently assigned this claim"
    end

    scenario "then I can assign the claim to someone else" do
      visit admin_claim_tasks_path(claim)
      expect(page).to have_content "This claim is currently assigned to #{second_admin.full_name}"
      click_link "Assign claim"

      expect(page).to have_text "Who would you like to assign this claim to?"
      choose "A colleague"
      select third_admin.full_name
      click_button "Save changes"

      expect(page.current_path).to eql "/admin/claims/#{claim.id}/tasks"
      expect(page).to have_text "This claim is currently assigned to #{third_admin.full_name}"
    end
  end
end
