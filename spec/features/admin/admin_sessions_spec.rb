require "rails_helper"

RSpec.feature "Admin session management" do
  context "when DfE sign in bypassed" do
    scenario "A user is redirected to the admin sign in page" do
      sign_in_as_service_operator

      allow(DfeSignIn::Config.instance).to receive(:bypass?).and_return(true)
      visit admin_claims_path
      allow(DfeSignIn::Config.instance).to receive(:bypass?).and_return(false)
      click_link("Sign out")

      expect(current_path).to eql(admin_sign_in_path)
    end
  end

  context "when DfE sign in not bypassed" do
    before do
      allow(DfeSignIn::Config.instance).to receive(:bypass?).and_return(false)
    end

    scenario "sign out link goes to DfE sign out" do
      sign_in_as_service_operator

      expect(page).to have_link("Sign out")
      expect(current_path).to eql(admin_root_path)
      expect(page).to have_link("Sign out", href: "https://issuer.example.com/session/end?post_logout_redirect_uri=https%3A%2F%2Ftest.example.com%2Fadmin%2Fauth%2Fsign-out&client_id=teacherpaymentsadmin")
    end
  end

  scenario "A user is redirected to their original url after sign in" do
    visit admin_claims_path

    expect(current_path).to eql(admin_sign_in_path)

    sign_in_as_service_operator

    expect(current_path).to eql(admin_claims_path)
  end

  scenario "accepting cookies does not affect sign in" do
    visit admin_sign_in_path
    click_button "Accept additional cookies"
    click_button "Hide cookie message"

    sign_in_as_service_operator

    expect(page).to have_content "Claims received"
  end
end
