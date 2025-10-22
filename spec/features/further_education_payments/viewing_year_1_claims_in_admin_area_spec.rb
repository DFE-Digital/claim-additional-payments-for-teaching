require "rails_helper"

RSpec.describe "Viewing year 1 claims in the admin area" do
  it "shows year 1 verification details" do
    eligibility = create(
      :further_education_payments_eligibility,
      :eligible,
      :year_one_verified,
      :identity_verified_by_provider
    )

    claim = create(
      :claim,
      :further_education,
      :submitted,
      eligibility: eligibility,
      date_of_birth: Date.new(1970, 1, 1),
      academic_year: AcademicYear.new("2024/2025"),
      onelogin_idv_at: DateTime.new(2024, 6, 1, 12, 0, 0),
      identity_confirmed_with_onelogin: false
    )

    sign_in_as_service_operator

    visit admin_claim_tasks_path(claim)

    click_on(
      "Confirm the provider has responded and verified the claimant’s information"
    )

    expect(page).to have_content("Provider Name #{claim.school.name}")
    expect(page).to have_content("UK Provider Reference Number (UKPRN) #{claim.school.ukprn}")
    expect(page).to have_content("This task was verified by the provider (Seymoure Skinner).")

    within_table_row("Contract of employment") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("Permanent contract")
      expect(provider_answer).to have_content("Yes")
    end

    within_table_row("Teaching responsibilities") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("Yes")
      expect(provider_answer).to have_content("Yes")
    end

    within_table_row("First 5 years of teaching") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("September 2023 to August 2024")
      expect(provider_answer).to have_content("Yes")
    end

    within_table_row("Timetabled teaching hours") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("12 or more hours per week, but fewer than 20")
      expect(provider_answer).to have_content("Yes")
    end

    within_table_row("Age range taught") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("Yes")
      expect(provider_answer).to have_content("No")
    end

    within_table_row("Subject") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("MathsPhysics")
      expect(provider_answer).to have_content("No")
    end

    within_table_row("Course Qualifications approved for funding at level 3 and below in the mathematics and statistics (opens in new tab) sector subject areaGCSE in maths, functional skills qualifications and other maths qualifications (opens in new tab) approved for teaching to 16 to 19-year-olds who meet the condition of funding") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("GCSE physics")
      expect(provider_answer).to have_content("No")
    end

    visit admin_claim_tasks_path(claim)

    click_on(
      "Confirm the provider has verified the claimant’s identity",
      match: :first
    )

    expect(page).to have_content("Provider Name #{claim.school.name}")
    expect(page).to have_content("UK Provider Reference Number (UKPRN) #{claim.school.ukprn}")
    expect(page).to have_content("Alternative identity verification")

    within_table_row("National Insurance number") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("QQ100000C")
      expect(provider_answer).to have_content("QQ123456C")
    end

    within_table_row("Post code") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("WIA OAA")
      expect(provider_answer).to have_content("W1A 1AA")
    end

    within_table_row("Date of Birth") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("1 January 1970")
      expect(provider_answer).to have_content("1 January 1990")
    end

    within_table_row("Passport number") do |claimant_answer, provider_answer|
      expect(claimant_answer).to have_content("No passport")
      expect(provider_answer).to have_content("123456789")
    end
  end

  def within_table_row(label, &block)
    within(first("tr", text: label)) do
      claimant_answer = find("td:first-of-type")
      provider_answer = find("td:last-of-type")

      yield(claimant_answer, provider_answer)
    end
  end
end
