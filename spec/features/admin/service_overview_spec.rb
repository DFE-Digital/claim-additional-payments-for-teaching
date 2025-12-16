require "rails_helper"

RSpec.describe "Service Overview Page", type: :feature do
  it "only allows admins to access the page" do
    visit "admin/service-overview"

    expect(page).to have_current_path("/admin/auth/sign-in")
  end

  it "shows the number of journeys at each step in the last 24 hours" do
    travel_to DateTime.new(2025, 12, 25, 0, 0, 0)

    create(
      :early_years_payment_provider_authenticated_session,
      steps: %w[
        consent
        current-nursery
        paye-reference
        claimant-name
        start-date
        contract-type
        child-facing
        returner
        returner-worked-with-children
        returner-contract-type
        employee-email
        check-your-answers
        confirmation
      ]
    )

    2.times do
      create(
        :early_years_payment_provider_authenticated_session,
        steps: %w[
          consent
          current-nursery
        ]
      )
    end

    3.times do
      create(
        :early_years_payment_practitioner_session,
        steps: %w[
          find-reference
          how-we-use-your-information
          sign-in
          full-name
          date-of-birth
          national-insurance-number
          postcode-search
          select-home-address
          address
          email-address
          email-verification
          provide-mobile-number
          mobile-number
          mobile-verification
          personal-bank-account
          gender
          check-your-answers
          confirmation
        ]
      )
    end

    create(
      :early_years_payment_practitioner_session,
      steps: %w[
        find-reference
      ]
    )

    4.times do
      create(
        :early_years_payment_practitioner_session,
        steps: %w[
          find-reference
          how-we-use-your-information
          sign-in
          full-name
          date-of-birth
          national-insurance-number
          postcode-search
          select-home-address
          address
          email-address
          email-verification
          provide-mobile-number
          mobile-number
          mobile-verification
          personal-bank-account
          gender
          check-your-answers
        ]
      )
    end

    3.times do
      create(
        :further_education_payments_session,
        steps: %w[
          have-one-login-account
        ]
      )
    end

    create(
      :further_education_payments_session,
      steps: %w[
        existing-progress
        check-eligibility-intro
        teaching-responsibilities
        further-education-provision-search
        select-provision
        further-education-teaching-start-year
        teaching-qualification
        contract-type
        fixed-term-contract
        taught-at-least-one-term
        teaching-hours-per-week
        half-teaching-hours
        subjects-taught
        building-construction-courses
        chemistry-courses
        computing-courses
        early-years-courses
        engineering-manufacturing-courses
        maths-courses
        physics-courses
      ]
    )

    3.times do
      create(
        :get_a_teacher_relocation_payment_session,
        steps: %w[
          previous-payment-received
          application-route
          state-funded-secondary-school
          current-school
          select-current-school
          headteacher-details
          contract-details
          start-date
          subject
          changed-workplace-or-new-contract
          breaks-in-employment
          visa
          entry-date
          check-your-answers-part-one
          information-provided
          nationality
          passport-number
          personal-details
          postcode-search
          select-home-address
          address
          email-address
          email-verification
          provide-mobile-number
          mobile-number
          mobile-verification
          personal-bank-account
          gender
          check-your-answers
          confirmation
        ]
      )
    end

    5.times do
      create(
        :targeted_retention_incentive_payments_session,
        steps: %w[
          check-eligibility-intro
          sign-in-or-continue
          reset-claim
          correct-school
          current-school
          select-current-school
          nqt-in-academic-year-after-itt
          supply-teacher
          entire-term-contract
          employed-directly
          poor-performance
          qualification-details
          qualification
          itt-year
          eligible-itt-subject
          eligible-degree-subject
          teaching-subject-now
          check-your-answers-part-one
          eligibility-confirmed
          information-provided
          personal-details
          postcode-search
          select-home-address
          address
          select-email
          email-address
          email-verification
          select-mobile
          provide-mobile-number
          mobile-number
          mobile-verification
          personal-bank-account
          gender
          teacher-reference-number
        ]
      )
    end

    3.times do
      create(
        :targeted_retention_incentive_payments_session,
        steps: %w[
          check-eligibility-intro
          sign-in-or-continue
          reset-claim
          correct-school
          current-school
          select-current-school
          nqt-in-academic-year-after-itt
          supply-teacher
          entire-term-contract
          employed-directly
          poor-performance
          qualification-details
          qualification
          itt-year
        ]
      )
    end

    3.times do
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        created_at: DateTime.new(2025, 12, 18)
      )

      create(
        :claim,
        policy: Policies::FurtherEducationPayments,
        created_at: DateTime.new(2025, 12, 19)
      )
    end

    2.times do
      create(
        :claim,
        policy: Policies::FurtherEducationPayments,
        created_at: DateTime.new(2025, 12, 18)
      )

      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        created_at: DateTime.new(2025, 12, 19)
      )
    end

    sign_in_as_service_operator

    visit "admin/service-overview"

    within '[data-test-id="early-years-payment-provider"]' do
      expect(page).to have_content("confirmation1")
      expect(page).to have_content("current-nursery2")
    end

    within '[data-test-id="early-years-payment-practitioner"]' do
      expect(page).to have_content("confirmation3")
      expect(page).to have_content("find-reference1")
      expect(page).to have_content("check-your-answers4")
    end

    within '[data-test-id="further-education-payments"]' do
      expect(page).to have_content("have-one-login-account3")
      expect(page).to have_content("physics-courses1")
    end

    within '[data-test-id="get-a-teacher-relocation-payment"]' do
      expect(page).to have_content("confirmation3")
    end

    within '[data-test-id="targeted-retention-incentive-payments"]' do
      expect(page).to have_content("teacher-reference-number5")
      expect(page).to have_content("itt-year3")
    end

    within '[data-test-id="claims-2025-12-18"]' do
      expect(page).to have_content("EarlyYearsPayments3")
      expect(page).to have_content("FurtherEducationPayments2")
    end

    within '[data-test-id="claims-2025-12-19"]' do
      expect(page).to have_content("FurtherEducationPayments3")
      expect(page).to have_content("EarlyYearsPayments2")
    end

    travel_back
  end
end
