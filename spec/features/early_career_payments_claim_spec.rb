require "rails_helper"

RSpec.feature "Teacher Early-Career Payments claims" do
  scenario "Teacher makes claim for 'Early-Career Payments' claim", js: true do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start Now"

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)
    expect(claim.eligibility.reload.current_school).to eql schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql false

    # - Performance Issues
    expect(page).to have_text(I18n.t("early_career_payments.questions.poor_performance"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action_hint"))

    # No
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"

    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action_hint"))

    # "No"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"

    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_formal_performance_action).to eql false
    expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql false

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Postgraduate ITT"
    click_on "Continue"

    expect(claim.eligibility.reload.qualification).to eq "postgraduate_itt"

    # - Which subject did you do your postgraduate ITT in
    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name))
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.hint.#{claim.eligibility.qualification}"))

    choose "Mathematics"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

    # - Do you teach maths now
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: claim.eligibility.eligible_itt_subject))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.teaching_subject_now).to eql true

    # - In what academic year did you start your undergraduate ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))
    expect(page).to have_text("If you did a part time ITT")

    choose "2018 - 2019"
    click_on "Continue"

    expect(claim.eligibility.reload.itt_academic_year).to eql "2018_2019"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

    %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    within(".govuk-summary-list") do
      expect(page).not_to have_text(I18n.t("questions.postgraduate_masters_loan"))
      expect(page).not_to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
    end
    click_on("Continue")

    # - You are eligible for an early career payment
    expect(page).to have_text("You are eligible " + I18n.t("early_career_payments.claim_description"))
    expect(page).to have_text("able to claim £7,500")

    within(".govuk-list--bullet") do
      expect(page).to have_text("your National Insurance number")
      ["bank account details", "teacher reference number", "student loan"].each do |bullet_point|
        expect(page).to have_text bullet_point
      end
    end
    click_on "Continue"

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details
    expect(page).to have_text(I18n.t("questions.personal_details"))
    expect(page).to have_text(I18n.t("questions.name"))

    fill_in "claim_first_name", with: "Russell"
    fill_in "claim_surname", with: "Wong"

    expect(page).to have_text(I18n.t("questions.date_of_birth"))

    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"

    expect(page).to have_text(I18n.t("early_career_payments.questions.national_insurance_number"))

    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(claim.reload.first_name).to eql("Russell")
    expect(claim.reload.surname).to eql("Wong")
    expect(claim.reload.date_of_birth).to eq(Date.new(1988, 2, 28))
    expect(claim.reload.national_insurance_number).to eq("PX321499A")

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

    click_link(I18n.t("questions.address.home.link_to_manual_address"))

    # - What is your address
    expect(page).to have_text(I18n.t("questions.address.generic.title"))

    fill_in :claim_address_line_1, with: "57"
    fill_in :claim_address_line_2, with: "Walthamstow Drive"
    fill_in "Town or city", with: "Derby"
    fill_in "County", with: "City of Derby"
    fill_in "Postcode", with: "DE22 4BS"
    click_on "Continue"

    expect(claim.reload.address_line_1).to eql("57")
    expect(claim.address_line_2).to eql("Walthamstow Drive")
    expect(claim.address_line_3).to eql("Derby")
    expect(claim.address_line_4).to eql("City of Derby")
    expect(claim.postcode).to eql("DE22 4BS")

    # - Email address
    expect(page).to have_text(I18n.t("questions.email_address"))

    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"

    expect(claim.reload.email_address).to eql("david.tau1988@hotmail.co.uk")

    # - One time password
    expect(page).to have_text("Email address verification")
    expect(page).to have_text("Enter the 6-digit password")
    expect(page).to have_text("We recommend you copy and paste the password from the email.")

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.body.decoded.scan(/\b[0-9]{6}\b/).first

    # - One time password wrong
    fill_in "claim_one_time_password", with: "000000"
    click_on "Confirm"
    expect(page).to have_text("Enter the correct one time password that we emailed to you")

    # - clear and enter correct OTP
    fill_in "claim_one_time_password", with: otp_in_mail_sent, fill_options: {clear: :backspace}
    click_on "Confirm"

    # - Provide mobile number
    expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.provide_mobile_number).to eql true

    # - Mobile number
    expect(page).to have_text(I18n.t("questions.mobile_number"))

    fill_in "claim_mobile_number", with: "07123456789"
    click_on "Continue"

    expect(claim.reload.mobile_number).to eql("07123456789")

    # - Mobile number one-time password
    # expect(page).to have_text("Password verification")
    # expect(page).to have_text("Enter the 6-digit password")
    # expect(page).not_to have_text("We recommend you copy and paste the password from the email.")

    # fill_in "claim_one_time_password", with: otp_sent_to_mobile
    # click_on "Confirm"

    # Payment to Bank or Building Society
    expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

    choose "Personal bank account"
    click_on "Continue"

    expect(claim.reload.bank_or_building_society).to eq "personal_bank_account"

    # - Enter bank account details
    expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
    expect(page).not_to have_text("Building society roll number")

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(claim.reload.banking_name).to eq("Jo Bloggs")
    expect(claim.bank_sort_code).to eq("123456")
    expect(claim.bank_account_number).to eq("87654321")

    # - What gender does your school's payroll system associate with you
    expect(page).to have_text(I18n.t("questions.payroll_gender"))

    choose "Female"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("female")

    # - What is your teacher reference number
    expect(page).to have_text(I18n.t("questions.teacher_reference_number"))

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    expect(claim.reload.teacher_reference_number).to eql("1234567")

    # - Are you currently paying off your student loan
    expect(page).to have_text(I18n.t("questions.has_student_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.has_student_loan).to eql true

    # - When you applied for your student loan where was your address
    expect(page).to have_text(I18n.t("questions.student_loan_country"))

    choose "England"
    click_on "Continue"

    expect(claim.reload.student_loan_country).to eql("england")

    # - How many higher education courses did you take a student loan out for
    expect(page).to have_text(I18n.t("questions.student_loan_how_many_courses"))

    choose "1"
    click_on "Continue"

    expect(claim.reload.student_loan_courses).to eql("one_course")

    # - When did the first year of your higher education course start
    expect(page).to have_text(I18n.t("questions.student_loan_start_date.one_course"))

    choose "Before 1 September 2012"
    click_on "Continue"

    expect(claim.reload.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
    expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)

    # - Did you take out a postgraduate masters loan on or after 1 August 2016
    expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.postgraduate_masters_loan).to eql true

    # - Did you take out a postgraduate doctoral loan on or after 1 August 2016
    expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.postgraduate_doctoral_loan).to eql true

    # - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")
    expect(page).not_to have_text("Eligibility details")
    %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
      expect(page).to have_text section_heading
    end

    within(".govuk-summary-list:nth-of-type(3)") do
      expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))
      expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
    end

    stub_geckoboard_dataset_update

    freeze_time do
      click_on "Accept and send"

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    # - Application complete (make sure its Word for Word and styling matches)
    expect(page).to have_text("Application complete")
    expect(page).to have_text("What happens next")
    expect(page).to have_text("Set a reminder for when your application window opens")
    expect(page).to have_text("What did you think of this service?")
    expect(page).to have_text(claim.reference)
  end

  scenario "Supply Teacher makes claim for 'Early Career Payments' with a contract to teach for entire term & employed directly by school" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start Now"

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:penistone_grammar_school)
    expect(claim.eligibility.reload.current_school).to eql schools(:penistone_grammar_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql true

    # - Do you have a contract to teach at the same school for an entire term or longer
    expect(page).to have_text(I18n.t("early_career_payments.questions.has_entire_term_contract"))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.has_entire_term_contract).to eql true

    # - Are you employed directly by your school
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_directly"))

    choose "Yes, I'm employed by my school"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_directly).to eql true

    # - Are you currently subject to action for poor performance
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
  end

  context "Route into teaching" do
    let(:claim) do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim
    end

    scenario "when Assessment only" do
      visit claim_path(claim.policy.routing_name, "qualification")

      # - What route into teaching did you take?
      expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

      choose "Assessment only"
      click_on "Continue"

      expect(claim.eligibility.reload.qualification).to eq "assessment_only"

      # - Which subject did you do your postgraduate ITT in
      expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name))

      choose "Mathematics"
      click_on "Continue"

      expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

      # - Do you teach maths now
      expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: claim.eligibility.eligible_itt_subject))

      choose "Yes"
      click_on "Continue"

      expect(claim.eligibility.reload.teaching_subject_now).to eql true

      # - In what academic year did you start your undergraduate ITT
      expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))
      expect(page).not_to have_text("You might still be eligible to claim if your ITT coincided with one of the academic years stated, even if it didn’t start or complete in one of those years.")

      choose "2018 - 2019"
      click_on "Continue"

      expect(claim.eligibility.reload.itt_academic_year).to eql "2018_2019"
    end

    scenario "when Overseas recognition" do
      visit claim_path(claim.policy.routing_name, "qualification")

      # - What route into teaching did you take?
      expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

      choose "Overseas recognition"
      click_on "Continue"

      expect(claim.eligibility.reload.qualification).to eq "overseas_recognition"

      # - Which subject did you do your postgraduate ITT in
      expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name))

      choose "Mathematics"
      click_on "Continue"

      expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

      # - Do you teach maths now
      expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: claim.eligibility.eligible_itt_subject))

      choose "Yes"
      click_on "Continue"

      expect(claim.eligibility.reload.teaching_subject_now).to eql true

      # - In what academic year did you you earn your qualified teacher status (QTS)?
      expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))
      expect(page).not_to have_text("You might still be eligible to claim if your ITT coincided with one of the academic years stated, even if it didn’t start or complete in one of those years.")

      choose "2018 - 2019"
      click_on "Continue"

      expect(claim.eligibility.reload.itt_academic_year).to eql "2018_2019"
    end
  end

  scenario "Teacher makes claim for 'Early Career Payments' without uplift school" do
    visit landing_page_path(EarlyCareerPayments.routing_name)
    expect(page).to have_link(href: EarlyCareerPayments.feedback_url)

    # - Landing (start)
    expect(page).to have_text(I18n.t("early_career_payments.landing_page"))
    click_on "Start Now"

    # - NQT in Academic Year after ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"))

    choose "Yes"
    click_on "Continue"

    claim = Claim.order(:created_at).last
    eligibility = claim.eligibility

    expect(eligibility.nqt_in_academic_year_after_itt).to eql true

    # - Which school do you teach at
    expect(page).to have_text(I18n.t("early_career_payments.questions.current_school_search"))

    choose_school schools(:hampstead_school)
    expect(claim.eligibility.reload.current_school).to eql schools(:hampstead_school)

    # - Are you currently employed as a supply teacher
    expect(page).to have_text(I18n.t("early_career_payments.questions.employed_as_supply_teacher"))

    choose "No"
    click_on "Continue"

    expect(claim.eligibility.reload.employed_as_supply_teacher).to eql false

    # - Performance Issues
    expect(page).to have_text(I18n.t("early_career_payments.questions.poor_performance"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.formal_performance_action_hint"))

    # No
    choose "claim_eligibility_attributes_subject_to_formal_performance_action_false"

    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action"))
    expect(page).to have_text(I18n.t("early_career_payments.questions.disciplinary_action_hint"))

    # "No"
    choose "claim_eligibility_attributes_subject_to_disciplinary_action_false"
    click_on "Continue"

    expect(claim.eligibility.reload.subject_to_formal_performance_action).to eql false
    expect(claim.eligibility.reload.subject_to_disciplinary_action).to eql false

    # - What route into teaching did you take?
    expect(page).to have_text(I18n.t("early_career_payments.questions.qualification.heading"))

    choose "Postgraduate ITT"
    click_on "Continue"

    expect(claim.eligibility.reload.qualification).to eq "postgraduate_itt"

    # - Which subject did you do your postgraduate ITT in
    expect(page).to have_text(I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: claim.eligibility.qualification_name))

    choose "Mathematics"
    click_on "Continue"

    expect(claim.eligibility.reload.eligible_itt_subject).to eql "mathematics"

    # - Do you teach maths now
    expect(page).to have_text(I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: claim.eligibility.eligible_itt_subject))

    choose "Yes"
    click_on "Continue"

    expect(claim.eligibility.reload.teaching_subject_now).to eql true

    # - In what academic year did you start your postgraduate ITT
    expect(page).to have_text(I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{claim.eligibility.qualification}"))

    choose "2018 - 2019"
    click_on "Continue"

    expect(claim.eligibility.reload.itt_academic_year).to eql "2018_2019"

    # - Check your answers for eligibility
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
    expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

    %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
      expect(page).not_to have_text section_heading
    end

    within(".govuk-summary-list") do
      expect(page).not_to have_text(I18n.t("questions.postgraduate_masters_loan"))
      expect(page).not_to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
    end

    click_on("Continue")

    # - You are eligible for an early career payment
    expect(page).to have_text("You are eligible " + I18n.t("early_career_payments.claim_description"))
    expect(page).to have_text("able to claim £5,000")

    within(".govuk-list--bullet") do
      expect(page).to have_text("your National Insurance number")
      ["bank account details", "teacher reference number", "student loan"].each do |bullet_point|
        expect(page).to have_text bullet_point
      end
    end
    click_on "Continue"

    # - How will we use the information you provide
    expect(page).to have_text("How we will use the information you provide")
    click_on "Continue"

    # - Personal details
    expect(page).to have_text(I18n.t("questions.personal_details"))
    expect(page).to have_text(I18n.t("questions.name"))

    fill_in "claim_first_name", with: "Russell"
    fill_in "claim_surname", with: "Wong"

    expect(page).to have_text(I18n.t("questions.date_of_birth"))

    fill_in "Day", with: "28"
    fill_in "Month", with: "2"
    fill_in "Year", with: "1988"

    expect(page).to have_text(I18n.t("early_career_payments.questions.national_insurance_number"))

    fill_in "National Insurance number", with: "PX321499A"
    click_on "Continue"

    expect(claim.reload.first_name).to eql("Russell")
    expect(claim.reload.surname).to eql("Wong")
    expect(claim.reload.date_of_birth).to eq(Date.new(1988, 2, 28))
    expect(claim.reload.national_insurance_number).to eq("PX321499A")

    # - What is your home address
    expect(page).to have_text(I18n.t("questions.address.home.title"))
    expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

    click_link(I18n.t("questions.address.home.link_to_manual_address"))

    # - What is your address
    expect(page).to have_text(I18n.t("questions.address.generic.title"))

    fill_in :claim_address_line_1, with: "88"
    fill_in :claim_address_line_2, with: "Deanborough Street"
    fill_in "Town or city", with: "Nottingham"
    fill_in "County", with: "Nottinghamshire"
    fill_in "Postcode", with: "M1 7HL"
    click_on "Continue"

    expect(claim.reload.address_line_1).to eql("88")
    expect(claim.address_line_2).to eql("Deanborough Street")
    expect(claim.address_line_3).to eql("Nottingham")
    expect(claim.address_line_4).to eql("Nottinghamshire")
    expect(claim.postcode).to eql("M1 7HL")

    # - Email address
    expect(page).to have_text(I18n.t("questions.email_address"))

    fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
    click_on "Continue"

    expect(claim.reload.email_address).to eql("david.tau1988@hotmail.co.uk")

    # - One time password
    expect(page).to have_text("Email address verification")
    expect(page).to have_text("Enter the 6-digit password")
    expect(page).to have_text("We recommend you copy and paste the password from the email.")

    mail = ActionMailer::Base.deliveries.last
    otp_in_mail_sent = mail.body.decoded.scan(/\b[0-9]{6}\b/).first

    fill_in "claim_one_time_password", with: otp_in_mail_sent
    click_on "Confirm"

    # - Provide mobile number
    expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.provide_mobile_number).to eql true

    # - Mobile number
    expect(page).to have_text(I18n.t("questions.mobile_number"))

    fill_in "Mobile number", with: "01234567899"
    click_on "Continue"

    expect(claim.reload.mobile_number).to eql "01234567899"

    # - Mobile number one-time password
    # expect(page).to have_text("Password verification")
    # expect(page).to have_text("Enter the 6-digit password")
    # expect(page).not_to have_text("We recommend you copy and paste the password from the email.")

    # fill_in "claim_one_time_password", with: otp_sent_to_mobile
    # click_on "Confirm"

    # Payment to Bank or Building Society
    expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

    choose "Personal bank account"
    click_on "Continue"

    expect(claim.reload.bank_or_building_society).to eq "personal_bank_account"

    # - Enter bank account details
    expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
    expect(page).not_to have_text("Building society roll number")

    fill_in "Name on your account", with: "Jo Bloggs"
    fill_in "Sort code", with: "123456"
    fill_in "Account number", with: "87654321"
    click_on "Continue"

    expect(claim.reload.banking_name).to eq("Jo Bloggs")
    expect(claim.bank_sort_code).to eq("123456")
    expect(claim.bank_account_number).to eq("87654321")

    # - What gender does your school's payroll system associate with you
    expect(page).to have_text(I18n.t("questions.payroll_gender"))

    choose "Female"
    click_on "Continue"

    expect(claim.reload.payroll_gender).to eq("female")

    # - What is your teacher reference number
    expect(page).to have_text(I18n.t("questions.teacher_reference_number"))

    fill_in :claim_teacher_reference_number, with: "1234567"
    click_on "Continue"

    expect(claim.reload.teacher_reference_number).to eql("1234567")

    # - Are you currently paying off your student loan
    expect(page).to have_text(I18n.t("questions.has_student_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.has_student_loan).to eql true

    # - When you applied for your student loan where was your address
    expect(page).to have_text(I18n.t("questions.student_loan_country"))

    choose "England"
    click_on "Continue"

    expect(claim.reload.student_loan_country).to eql("england")
    # - How many higher education courses did you take a student loan out for
    expect(page).to have_text(I18n.t("questions.student_loan_how_many_courses"))

    choose "1"
    click_on "Continue"

    expect(claim.reload.student_loan_courses).to eql("one_course")
    # - When did the first year of your higher education course start
    expect(page).to have_text(I18n.t("questions.student_loan_start_date.one_course"))

    choose "Before 1 September 2012"
    click_on "Continue"

    expect(claim.reload.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
    expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)

    # - Did you take out a postgraduate masters loan on or after 1 August 2016
    expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.postgraduate_masters_loan).to eql true

    # - Did you take out a postgraduate doctoral loan on or after 1 August 2016
    expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))

    choose "Yes"
    click_on "Continue"

    expect(claim.reload.postgraduate_doctoral_loan).to eql true

    # - Check your answers before sending your application
    expect(page).to have_text("Check your answers before sending your application")
    expect(page).not_to have_text("Eligibility details")
    %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
      expect(page).to have_text section_heading
    end

    within(".govuk-summary-list:nth-of-type(3)") do
      expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))
      expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
    end

    stub_geckoboard_dataset_update

    freeze_time do
      click_on "Accept and send"

      expect(claim.reload.submitted_at).to eq(Time.zone.now)
    end

    # - Application complete (make sure its Word for Word and styling matches)
    expect(page).to have_text("Application complete")
    expect(page).to have_text("What happens next")
    expect(page).to have_text("Set a reminder for when your application window opens")
    expect(page).to have_text("What did you think of this service?")
    expect(page).to have_text(claim.reference)
  end

  context "When auto-populating address details" do
    before do
      body = <<-RESULTS
        {
          "header" : {
            "uri" : "https://api.os.uk/search/places/v1/postcode?postcode=SO169FX",
            "query" : "postcode=SO169FX",
            "offset" : 0,
            "totalresults" : 50,
            "format" : "JSON",
            "dataset" : "DPA",
            "lr" : "EN,CY",
            "maxresults" : 100,
            "epoch" : "85",
            "output_srs" : "EPSG:27700"
          },
          "results" : [
            {
              "DPA" : {
                "UPRN" : "100062039919",
                "UDPRN" : "22785699",
                "ADDRESS" : "FLAT 1, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                "SUB_BUILDING_NAME" : "FLAT 1",
                "BUILDING_NAME" : "MILLBROOK TOWER",
                "THOROUGHFARE_NAME" : "WINDERMERE AVENUE",
                "POST_TOWN" : "SOUTHAMPTON",
                "POSTCODE" : "SO16 9FX",
                "RPC" : "2",
                "X_COORDINATE" : 438092.0,
                "Y_COORDINATE" : 114637.0,
                "STATUS" : "APPROVED",
                "LOGICAL_STATUS_CODE" : "1",
                "CLASSIFICATION_CODE" : "RD06",
                "CLASSIFICATION_CODE_DESCRIPTION" : "Self Contained Flat (Includes Maisonette / Apartment)",
                "LOCAL_CUSTODIAN_CODE" : 1780,
                "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "SOUTHAMPTON",
                "POSTAL_ADDRESS_CODE" : "D",
                "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
                "BLPU_STATE_CODE" : "2",
                "BLPU_STATE_CODE_DESCRIPTION" : "In use",
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000016364569",
                "PARENT_UPRN" : "100062691379",
                "LAST_UPDATE_DATE" : "12/11/2018",
                "ENTRY_DATE" : "03/05/2001",
                "BLPU_STATE_DATE" : "11/12/2007",
                "LANGUAGE" : "EN",
                "MATCH" : 1.0,
                "MATCH_DESCRIPTION" : "EXACT"
              }
            },
            {
              "DPA" : {
                "UPRN" : "100062039928",
                "UDPRN" : "22785700",
                "ADDRESS" : "FLAT 10, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                "SUB_BUILDING_NAME" : "FLAT 10",
                "BUILDING_NAME" : "MILLBROOK TOWER",
                "THOROUGHFARE_NAME" : "WINDERMERE AVENUE",
                "POST_TOWN" : "SOUTHAMPTON",
                "POSTCODE" : "SO16 9FX",
                "RPC" : "2",
                "X_COORDINATE" : 438092.0,
                "Y_COORDINATE" : 114637.0,
                "STATUS" : "APPROVED",
                "LOGICAL_STATUS_CODE" : "1",
                "CLASSIFICATION_CODE" : "RD06",
                "CLASSIFICATION_CODE_DESCRIPTION" : "Self Contained Flat (Includes Maisonette / Apartment)",
                "LOCAL_CUSTODIAN_CODE" : 1780,
                "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "SOUTHAMPTON",
                "POSTAL_ADDRESS_CODE" : "D",
                "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
                "BLPU_STATE_CODE" : "2",
                "BLPU_STATE_CODE_DESCRIPTION" : "In use",
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000016364569",
                "PARENT_UPRN" : "100062691379",
                "LAST_UPDATE_DATE" : "12/11/2018",
                "ENTRY_DATE" : "03/05/2001",
                "BLPU_STATE_DATE" : "11/12/2007",
                "LANGUAGE" : "EN",
                "MATCH" : 1.0,
                "MATCH_DESCRIPTION" : "EXACT"
              }
            },
            {
              "DPA" : {
                "UPRN" : "100062039929",
                "UDPRN" : "22785701",
                "ADDRESS" : "FLAT 11, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
                "SUB_BUILDING_NAME" : "FLAT 11",
                "BUILDING_NAME" : "MILLBROOK TOWER",
                "THOROUGHFARE_NAME" : "WINDERMERE AVENUE",
                "POST_TOWN" : "SOUTHAMPTON",
                "POSTCODE" : "SO16 9FX",
                "RPC" : "2",
                "X_COORDINATE" : 438092.0,
                "Y_COORDINATE" : 114637.0,
                "STATUS" : "APPROVED",
                "LOGICAL_STATUS_CODE" : "1",
                "CLASSIFICATION_CODE" : "RD06",
                "CLASSIFICATION_CODE_DESCRIPTION" : "Self Contained Flat (Includes Maisonette / Apartment)",
                "LOCAL_CUSTODIAN_CODE" : 1780,
                "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "SOUTHAMPTON",
                "POSTAL_ADDRESS_CODE" : "D",
                "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
                "BLPU_STATE_CODE" : "2",
                "BLPU_STATE_CODE_DESCRIPTION" : "In use",
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000016364569",
                "PARENT_UPRN" : "100062691379",
                "LAST_UPDATE_DATE" : "12/11/2018",
                "ENTRY_DATE" : "03/05/2001",
                "BLPU_STATE_DATE" : "11/12/2007",
                "LANGUAGE" : "EN",
                "MATCH" : 1.0,
                "MATCH_DESCRIPTION" : "EXACT"
              }
            }
          ]
        }
      RESULTS

      stub_request(:get, "https://api.os.uk/search/places/v1/postcode?key=api-key-value&postcode=SO169FX")
        .with(
          headers: {
            "Content-Type" => "application/json",
            "Expect" => "",
            "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus"
          }
        ).to_return(status: 200, body: body, headers: {})
    end

    let(:claim) do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim
    end

    scenario "with Ordnance Survey data" do
      expect(claim.valid?(:submit)).to eq false
      visit claim_path(claim.policy.routing_name, "check-your-answers-part-one")

      # - Check your answers for eligibility
      expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.primary_heading"))
      expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.secondary_heading"))
      expect(page).to have_text(I18n.t("early_career_payments.check_your_answers.part_one.confirmation_notice"))

      %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
        expect(page).not_to have_text section_heading
      end

      within(".govuk-summary-list") do
        expect(page).not_to have_text(I18n.t("questions.postgraduate_masters_loan"))
        expect(page).not_to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
      end

      click_on("Continue")

      # - You are eligible for an early career payment
      expect(page).to have_text("You are eligible " + I18n.t("early_career_payments.claim_description"))
      expect(page).to have_text("able to claim £7,500")

      within(".govuk-list--bullet") do
        expect(page).to have_text("your National Insurance number")
        ["bank account details", "teacher reference number", "student loan"].each do |bullet_point|
          expect(page).to have_text bullet_point
        end
      end
      click_on "Continue"

      # - How will we use the information you provide
      expect(page).to have_text("How we will use the information you provide")
      click_on "Continue"

      # - Personal details
      expect(page).to have_text(I18n.t("questions.personal_details"))
      expect(page).to have_text(I18n.t("questions.name"))

      fill_in "claim_first_name", with: "Russell"
      fill_in "claim_surname", with: "Wong"

      expect(page).to have_text(I18n.t("questions.date_of_birth"))

      fill_in "Day", with: "28"
      fill_in "Month", with: "2"
      fill_in "Year", with: "1988"

      expect(page).to have_text(I18n.t("early_career_payments.questions.national_insurance_number"))

      fill_in "National Insurance number", with: "PX321499A"
      click_on "Continue"

      expect(claim.reload.first_name).to eql("Russell")
      expect(claim.reload.surname).to eql("Wong")
      expect(claim.reload.date_of_birth).to eq(Date.new(1988, 2, 28))
      expect(claim.reload.national_insurance_number).to eq("PX321499A")

      # - What is your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))

      choose "flat_11_millbrook_tower_windermere_avenue_southampton_so16_9fx"
      click_on "Continue"

      expect(claim.reload.address_line_1).to eql "Flat 11, Millbrook Tower"
      expect(claim.address_line_2).to eql "Windermere Avenue"
      expect(claim.address_line_3).to eql "Southampton"
      expect(claim.postcode).to eql "SO16 9FX"

      # - What is your address
      expect(page).not_to have_text(I18n.t("questions.address.generic.title"))

      # - Email address
      expect(page).to have_text(I18n.t("questions.email_address"))

      fill_in "Email address", with: "david.tau1988@hotmail.co.uk"
      click_on "Continue"

      expect(claim.reload.email_address).to eql("david.tau1988@hotmail.co.uk")

      # - One time password
      expect(page).to have_text("Email address verification")
      expect(page).to have_text("Enter the 6-digit password")
      expect(page).to have_text("We recommend you copy and paste the password from the email.")

      mail = ActionMailer::Base.deliveries.last
      otp_in_mail_sent = mail.body.decoded.scan(/\b[0-9]{6}\b/).first

      fill_in "claim_one_time_password", with: otp_in_mail_sent
      click_on "Confirm"

      # - Provide mobile number
      expect(page).to have_text(I18n.t("questions.provide_mobile_number"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.provide_mobile_number).to eql true

      # - Mobile number
      expect(page).to have_text(I18n.t("questions.mobile_number"))

      fill_in "Mobile number", with: "01234567899"
      click_on "Continue"

      expect(claim.reload.mobile_number).to eql "01234567899"

      # - Mobile number one-time password
      # expect(page).to have_text("Password verification")
      # expect(page).to have_text("Enter the 6-digit password")
      # expect(page).not_to have_text("We recommend you copy and paste the password from the email.")

      # fill_in "claim_one_time_password", with: otp_sent_to_mobile
      # click_on "Confirm"

      # Payment to Bank or Building Society
      expect(page).to have_text(I18n.t("questions.bank_or_building_society"))

      choose "Personal bank account"
      click_on "Continue"

      expect(claim.reload.bank_or_building_society).to eq "personal_bank_account"

      # - Enter bank account details
      expect(page).to have_text(I18n.t("questions.account_details", bank_or_building_society: claim.bank_or_building_society.humanize.downcase))
      expect(page).not_to have_text("Building society roll number")

      fill_in "Name on your account", with: "Jo Bloggs"
      fill_in "Sort code", with: "123456"
      fill_in "Account number", with: "87654321"
      click_on "Continue"

      expect(claim.reload.banking_name).to eq("Jo Bloggs")
      expect(claim.bank_sort_code).to eq("123456")
      expect(claim.bank_account_number).to eq("87654321")

      # - What gender does your school's payroll system associate with you
      expect(page).to have_text(I18n.t("questions.payroll_gender"))

      choose "Female"
      click_on "Continue"

      expect(claim.reload.payroll_gender).to eq("female")

      # - What is your teacher reference number
      expect(page).to have_text(I18n.t("questions.teacher_reference_number"))

      fill_in :claim_teacher_reference_number, with: "1234567"
      click_on "Continue"

      expect(claim.reload.teacher_reference_number).to eql("1234567")

      # - Are you currently paying off your student loan
      expect(page).to have_text(I18n.t("questions.has_student_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.has_student_loan).to eql true

      # - When you applied for your student loan where was your address
      expect(page).to have_text(I18n.t("questions.student_loan_country"))

      choose "England"
      click_on "Continue"

      expect(claim.reload.student_loan_country).to eql("england")
      # - How many higher education courses did you take a student loan out for
      expect(page).to have_text(I18n.t("questions.student_loan_how_many_courses"))

      choose "1"
      click_on "Continue"

      expect(claim.reload.student_loan_courses).to eql("one_course")
      # - When did the first year of your higher education course start
      expect(page).to have_text(I18n.t("questions.student_loan_start_date.one_course"))

      choose "Before 1 September 2012"
      click_on "Continue"

      expect(claim.reload.student_loan_start_date).to eq(StudentLoan::BEFORE_1_SEPT_2012)
      expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)

      # - Did you take out a postgraduate masters loan on or after 1 August 2016
      expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.postgraduate_masters_loan).to eql true

      # - Did you take out a postgraduate doctoral loan on or after 1 August 2016
      expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))

      choose "Yes"
      click_on "Continue"

      expect(claim.reload.postgraduate_doctoral_loan).to eql true

      # - Check your answers before sending your application
      expect(page).to have_text("Check your answers before sending your application")
      expect(page).not_to have_text("Eligibility details")
      %w[Identity\ details Payment\ details Student\ loan\ details].each do |section_heading|
        expect(page).to have_text section_heading
      end

      within(".govuk-summary-list:nth-of-type(3)") do
        expect(page).to have_text(I18n.t("questions.postgraduate_masters_loan"))
        expect(page).to have_text(I18n.t("questions.postgraduate_doctoral_loan"))
      end

      stub_geckoboard_dataset_update

      freeze_time do
        click_on "Accept and send"

        expect(claim.reload.submitted_at).to eq(Time.zone.now)
      end

      # - Application complete (make sure its Word for Word and styling matches)
      expect(page).to have_text("Application complete")
      expect(page).to have_text("What happens next")
      expect(page).to have_text("Set a reminder for when your application window opens")
      expect(page).to have_text("What did you think of this service?")
      expect(page).to have_text(claim.reference)
    end
  end
end
