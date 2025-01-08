require "rails_helper"

RSpec.feature "Admin views claim details for EarlyYearsPayments" do
  before do
    travel_to Date.new(2020, 2, 1)
    sign_in_as_service_operator
    visit admin_claim_path(claim)
  end

  let(:eligible_ey_provider) { create(:eligible_ey_provider) }

  context "provider journey submitted" do
    let!(:claim) do
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        reference: "AB123456",
        first_name: "Bruce",
        surname: "Wayne",
        email_address: nil,
        mobile_number: nil,
        practitioner_email_address: "practitioner@example.com",
        paye_reference: "123/A",
        provider_contact_name: "John Doe",
        started_at: DateTime.new(2020, 1, 1, 12, 0, 0),
        student_loan_plan: "not_applicable",
        eligibility_attributes: {
          nursery_urn: eligible_ey_provider.urn,
          start_date: Date.new(2018, 1, 1),
          award_amount: 1000,
          provider_email_address: "provider@example.com",
          child_facing_confirmation_given: true,
          returning_within_6_months: true,
          returner_worked_with_children: false,
          returner_contract_type: "casual or temporary",
          provider_claim_submitted_at: DateTime.new(2020, 1, 2, 12, 0, 0)
        }
      )
    end

    it "shows the claim details" do
      expect(summary_row("Applicant name")).to have_content("Bruce Wayne")
      expect(summary_row("Contact email")).to have_content("")
      expect(summary_row("Provider-input contact email")).to have_content("practitioner@example.com")
      expect(summary_row("Nursery name")).to have_content(eligible_ey_provider.nursery_name)
      expect(summary_row("Start date")).to have_content("1 January 2018")
      expect(summary_row("PAYE reference")).to have_content("123/A")

      expect(summary_row("Provider email address")).to have_content("provider@example.com")
      expect(summary_row("Provider name")).to have_content("John Doe")
      expect(summary_row("Declaration of collected consent")).to have_content("Confirmed")
      expect(summary_row("Does the employee spend more than 70% in the job working with children?")).to have_content("Yes")
      expect(summary_row("Did the employee work in an early years setting in the previous 6 months?")).to have_content("Yes")
      expect(summary_row("Did the employee’s previous job involve working directly with children?")).to have_content("No")
      expect(summary_row("What was the employee’s previous job contract type?")).to have_content("casual or temporary")

      expect(summary_row("Early years financial incentive payment")).to have_content("£1,000")

      expect(summary_row("Student loan repayment plan")).to have_content("Not applicable")

      expect(summary_row("Provider started at")).to have_content("1 January 2020 12:00pm")
      expect(summary_row("Provider submitted at")).to have_content("2 January 2020 12:00pm")
    end
  end

  context "practitioner journey submitted" do
    let(:claim) do
      create(
        :claim,
        policy: Policies::EarlyYearsPayments,
        reference: "AB234567",
        first_name: "Bruce",
        surname: "Wayne",
        national_insurance_number: "QQ123456C",
        email_address: "test@example.com",
        mobile_number: "07700900000",
        practitioner_email_address: "practitioner@example.com",
        address_line_1: "Flat 1",
        address_line_2: "1 Test Road",
        address_line_3: "Test Town",
        postcode: "AB1 2CD",
        date_of_birth: Date.new(1901, 1, 1),
        paye_reference: "123/A",
        provider_contact_name: "John Doe",
        started_at: DateTime.new(2020, 1, 1, 12, 0, 0),
        submitted_at: DateTime.new(2020, 1, 4, 12, 0, 0),
        student_loan_plan: "not_applicable",
        eligibility_attributes: {
          nursery_urn: eligible_ey_provider.urn,
          start_date: Date.new(2018, 1, 1),
          award_amount: 1000,
          provider_email_address: "provider@example.com",
          child_facing_confirmation_given: true,
          returning_within_6_months: true,
          returner_worked_with_children: false,
          returner_contract_type: "casual or temporary",
          provider_claim_submitted_at: DateTime.new(2020, 1, 2, 12, 0, 0),
          practitioner_claim_started_at: DateTime.new(2020, 1, 3, 12, 0, 0)
        }
      )
    end

    it "shows the claim details" do
      expect(summary_row("Applicant name")).to have_content("Bruce Wayne")
      expect(summary_row("Date of birth")).to have_content("1 January 1901")
      expect(summary_row("National Insurance number")).to have_content("QQ123456C")
      expect(summary_row("Address")).to have_content("Flat 1")
      expect(summary_row("Address")).to have_content("1 Test Road")
      expect(summary_row("Address")).to have_content("Test Town")
      expect(summary_row("Address")).to have_content("AB1 2CD")
      expect(summary_row("Contact email")).to have_content("test@example.com")
      expect(summary_row("Provider-input contact email")).to have_content("practitioner@example.com")
      expect(summary_row("Mobile number")).to have_content("07700900000")
      expect(summary_row("Nursery name")).to have_content(eligible_ey_provider.nursery_name)
      expect(summary_row("Start date")).to have_content("1 January 2018")
      expect(summary_row("PAYE reference")).to have_content("123/A")

      expect(summary_row("Provider email address")).to have_content("provider@example.com")
      expect(summary_row("Provider name")).to have_content("John Doe")
      expect(summary_row("Declaration of collected consent")).to have_content("Confirmed")
      expect(summary_row("Does the employee spend more than 70% in the job working with children?")).to have_content("Yes")
      expect(summary_row("Did the employee work in an early years setting in the previous 6 months?")).to have_content("Yes")
      expect(summary_row("Did the employee’s previous job involve working directly with children?")).to have_content("No")
      expect(summary_row("What was the employee’s previous job contract type?")).to have_content("casual or temporary")

      expect(summary_row("Early years financial incentive payment")).to have_content("£1,000")

      expect(summary_row("Student loan repayment plan")).to have_content("Not applicable")

      expect(summary_row("Provider started at")).to have_content("1 January 2020 12:00pm")
      expect(summary_row("Provider submitted at")).to have_content("2 January 2020 12:00pm")
      expect(summary_row("Claimant started at")).to have_content("3 January 2020 12:00pm")
      expect(summary_row("Claimant submitted at")).to have_content("4 January 2020 12:00")
      expect(page).to have_summary_item(key: "Decision deadline", value: "1 July 2018")
      expect(summary_row("Overdue")).to have_content("-580 days")
    end
  end

  def summary_row(label)
    find("dt", text: label).sibling("dd")
  end
end
