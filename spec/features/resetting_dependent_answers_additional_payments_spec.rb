require "rails_helper"

RSpec.describe "Additional payments resetting dependent answers" do
  let!(:journey_configuration) do
    create(:journey_configuration, :additional_payments)
  end

  let(:ecp_eligibility) do
    create(
      :early_career_payments_eligibility,
      :eligible_now,
      employed_as_supply_teacher: false,
      qualification: :postgraduate_itt,
      itt_academic_year: journey_configuration.current_academic_year - 3,
      eligible_itt_subject: :mathematics
    )
  end

  let(:lup_eligibility) do
    create(
      :levelling_up_premium_payments_eligibility,
      :eligible_now,
      employed_as_supply_teacher: false,
      qualification: :postgraduate_itt,
      itt_academic_year: journey_configuration.current_academic_year - 3,
      eligible_itt_subject: :mathematics
    )
  end

  let(:ecp_claim) do
    create(
      :claim,
      eligibility: ecp_eligibility,
      policy: Policies::EarlyCareerPayments
    )
  end

  let(:lup_claim) do
    create(
      :claim,
      eligibility: lup_eligibility,
      policy: Policies::LevellingUpPremiumPayments
    )
  end

  let(:claims) { [ecp_claim, lup_claim] }

  before do
    complete_claim(claims)
    visit "/additional-payments/check-your-answers-part-one"
    # Sanity check
    expect(page).to have_content("Check your answers")
  end

  scenario "changing employed_as_supply_teacher resets dependent answers" do
    expect(page).to have_content(
      "Are you currently employed as a supply teacher? No"
    )

    link_to_change_employed_as_supply_teacher = find(
      %([aria-label="Change are you currently employed as a supply teacher?"])
    )

    link_to_change_employed_as_supply_teacher.click

    # /supply-teacher
    expect(page).to have_content(
      "Are you currently employed as a supply teacher?"
    )

    choose "Yes"

    click_on "Continue"

    # /entire-term-contract
    expect(page).to have_content(
      "Do you have a contract to teach at the same school for an entire term or longer?"
    )

    choose "Yes"

    click_on "Continue"

    # /employed-directly
    expect(page).to have_content("Are you employed directly by your school?")

    choose "Yes"

    click_on "Continue"

    # /poor-performance
    expect(page).to have_content(
      "Tell us if you are currently under any performance measures or disciplinary action"
    )

    # options not reset so we can just continue
    click_on "Continue"

    # /qualification
    expect(page).to have_content("Which route into teaching did you take?")

    # options not reset so we can just continue
    click_on "Continue"

    # /itt-year
    expect(page).to have_content(
      "In which academic year did you start your postgraduate initial teacher training (ITT)?"
    )

    # options not reset so we can just continue
    click_on "Continue"

    # /eligible-itt-subject
    expect(page).to have_content(
      "Which subject did you do your postgraduate initial teacher training (ITT) in?"
    )

    # Not sure why this option isn't reset but as of `ccab16af` it isn't
    choose "Mathematics"

    click_on "Continue"

    # /teaching-subject-now
    expect(page).to have_content(
      "Do you spend at least half of your contracted hours teaching eligible subjects?"
    )

    choose "Yes"

    click_on "Continue"

    # /check-your-answers-part-one
    expect(page).to have_content("Check your answers")

    expect(page).to have_content(
      "Do you have a contract to teach at the same school for an entire term or longer? Yes"
    )

    expect(page).to have_content("Are you employed directly by your school? Yes")

    # /supply-teacher
    link_to_change_employed_as_supply_teacher = find(
      %([aria-label="Change are you currently employed as a supply teacher?"])
    )

    link_to_change_employed_as_supply_teacher.click

    choose "No"

    click_on "Continue"

    # /poor-performance
    expect(page).to have_content(
      "Tell us if you are currently under any performance measures or disciplinary action"
    )

    # options not reset so we can just continue
    click_on "Continue"

    # /qualification
    expect(page).to have_content("Which route into teaching did you take?")

    # options not reset so we can just continue
    click_on "Continue"

    # /itt-year
    expect(page).to have_content(
      "In which academic year did you start your postgraduate initial teacher training (ITT)?"
    )

    # options not reset so we can just continue
    click_on "Continue"

    # /eligible-itt-subject
    expect(page).to have_content(
      "Which subject did you do your postgraduate initial teacher training (ITT) in?"
    )

    # Not sure why this option isn't reset but as of `ccab16af` it isn't
    choose "Mathematics"

    click_on "Continue"

    # /teaching-subject-now
    expect(page).to have_content(
      "Do you spend at least half of your contracted hours teaching eligible subjects?"
    )

    choose "Yes"

    click_on "Continue"

    # /check-your-answers-part-one
    expect(page).to have_content("Check your answers")

    # Expect not to see to see employed directly by school
    expect(page).not_to have_content(
      "Do you have a contract to teach at the same school for an entire term or longer?"
    )

    expect(page).not_to have_content("Are you employed directly by your school?")
  end

  scenario "changing qualification resets dependent answers" do
    expect(page).to have_content(
      "Which route into teaching did you take? " \
      "Postgraduate initial teacher training (ITT)"
    )

    link_to_change_qualification = find(
      %([aria-label="Change which route into teaching did you take?"])
    )

    link_to_change_qualification.click

    # /qualification
    # Change qualification
    choose "Undergraduate initial teacher training (ITT)"

    click_on "Continue"

    # /itt-year with answer preselected
    expect(page).to have_content(
      "In which academic year did you complete your " \
      "undergraduate initial teacher training (ITT)?"
    )

    existing_itt_year = find_field(
      ecp_eligibility.itt_academic_year.to_s.gsub("/", " to ")
    )

    expect(existing_itt_year).to be_checked

    click_on "Continue"

    # /eligible-itt-subject
    expect(page).to have_content(
      "Which subject did you do your " \
      "undergraduate initial teacher training (ITT) in?"
    )

    # No option selected as the answer is depenedent on "qualification" so is
    # reset
    all("input[type=radio]").each do |radio|
      expect(radio).not_to be_checked
    end

    choose "Mathematics"
    click_on "Continue"

    # /teaching-subject-now
    expect(page).to have_content(
      "Do you spend at least half of your contracted hours " \
      "teaching eligible subjects?"
    )

    choose "Yes"
    click_on "Continue"

    # /check-your-answers-part-one
    expect(page).to have_content("Check your answers")
  end

  scenario "changing eligible_itt_subject resets dependent answers" do
    expect(page).to have_content(
      "Which subject did you do your postgraduate initial teacher training (ITT) in?"
    )

    link_to_change_subject = find(
      %{[aria-label="Change which subject did you do your postgraduate initial teacher training (itt) in?"]}
    )

    link_to_change_subject.click

    # /eligible-itt-subject
    expect(page).to have_content(
      "Which subject did you do your postgraduate initial teacher training (ITT) in?"
    )

    # Was mathematics
    choose("Physics")

    click_on "Continue"

    # /teaching-subject-now
    expect(page).to have_content(
      "Do you spend at least half of your contracted hours teaching eligible subjects?"
    )

    # No option selected as the answer is depenedent on "eligible_itt_subject"
    # so is reset
    all("input[type=radio]").each do |radio|
      expect(radio).not_to be_checked
    end

    choose "Yes"

    click_on "Continue"

    # /check-your-answers-part-one
    expect(page).to have_content("Check your answers")
  end

  scenario "changing itt_academic_year resets dependent answers" do
    expect(page).to have_content(
      "In which academic year did you start your postgraduate initial teacher training (ITT)? " +
      ecp_eligibility.itt_academic_year.to_s.gsub("/", " - ")
    )

    link_to_change_itt_year = find(
      %{[aria-label="Change in which academic year did you start your postgraduate initial teacher training (itt)?"]}
    )

    link_to_change_itt_year.click

    # /itt-year
    expect(page).to have_content(
      "In which academic year did you start your postgraduate initial teacher training (ITT)?"
    )

    new_academic_year = journey_configuration.current_academic_year - 1
    # pull this off journey configuration
    choose new_academic_year.to_s.gsub("/", " to ")

    click_on "Continue"

    # /eligible-itt-subject
    expect(page).to have_content(
      "Which subject did you do your postgraduate initial teacher training (ITT) in?"
    )

    # No option selected as the answer is depenedent on "itt_academic_year" so
    # is reset
    all("input[type=radio]").each do |radio|
      expect(radio).not_to be_checked
    end

    choose "Mathematics"

    click_on "Continue"

    # /teaching-subject-now
    expect(page).to have_content(
      "Do you spend at least half of your contracted hours teaching eligible subjects?"
    )

    choose "Yes"

    click_on "Continue"

    # /check-your-answers-part-one
    expect(page).to have_content("Check your answers")
  end

  # NOTE we could replace this method with the steps required to complete the
  # journey via the ui.
  def complete_claim(claims)
    visited_slugs = Journeys::AdditionalPaymentsForTeaching::SlugSequence::SLUGS
      .take_while { |slug| slug != "check-your-answers-part-one" }

    set_session({
      claim_id: claims.map(&:id),
      last_seen_at: Time.zone.now,
      slugs: visited_slugs
    })
  end

  def set_session(hash)
    session_hash = {"session_id" => SecureRandom.hex(16)}.merge(hash)
    cookie_jar = ActionDispatch::TestRequest.create.cookie_jar
    session_key = Rails.configuration.session_options[:key]
    cookie_jar.signed_or_encrypted[session_key] = {value: session_hash}
    page.driver.browser.set_cookie(cookie_jar.to_header)
  end
end
