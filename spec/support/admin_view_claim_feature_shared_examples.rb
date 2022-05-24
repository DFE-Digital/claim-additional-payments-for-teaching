RSpec.shared_examples "Admin View Claim Feature" do |policy|
  let!(:claim) {
    create(
      :claim,
      :submitted,
      eligibility: build("#{policy.to_s.underscore}_eligibility".to_sym, :eligible)
    )
  }

  before do
    @signed_in_user = sign_in_as_service_operator
  end

  scenario "view full claim details from index" do
    visit admin_claims_path

    find("a[href='#{admin_claim_tasks_path(claim)}']").click

    expect(page).to have_content(policy.short_name)

    expect_page_to_have_policy_sections policy

    click_on "View full claim"
    expect(page).to have_content(policy.short_name)
  end

  def expect_page_to_have_policy_sections(policy)
    sections = case policy
    when StudentLoans
      ["Identity confirmation", "Qualifications", "Census subjects taught", "Employment", "Student loan amount", "Decision"]
    when MathsAndPhysics
      ["Identity confirmation", "Qualifications", "Employment", "Decision"]
    else
      ["Identity confirmation", "Qualifications", "Census subjects taught", "Employment", "Decision"]
    end

    sections.each_with_index do |title, i|
      expect(page).to have_content("#{i + 1}. #{title}")
    end

    expect(page).to have_no_content("#{sections.count + 1}. ")
  end
end
