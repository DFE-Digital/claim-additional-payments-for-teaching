require "rails_helper"

RSpec.describe(
  Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck
) do
  def employment(
    name: "Oak Tree Nursery",
    postcode: "SW1A 1AA",
    paye_reference: nil
  )
    {
      "employer" => {
        "payeReference" => paye_reference,
        "name" => name,
        "address" => {
          "postcode" => postcode
        }
      }
    }
  end

  def check_for(
    employments: [employment],
    setting_name: "Oak Tree Nursery",
    setting_postcode: "SW1A 1AA",
    setting_paye_reference: nil,
    status: 200,
    body: nil
  )
    setting = build(
      :eligible_eytfi_provider,
      name: setting_name,
      postcode: setting_postcode,
      paye_reference: setting_paye_reference
    )
    described_class.new(
      setting: setting,
      hmrc_response_status: status,
      hmrc_response_body: body || {
        "employments" => employments
      }.to_json
    )
  end

  describe "response handling and dispatch" do
    it "looks back one calendar month, including across a year boundary" do
      travel_to Time.zone.local(2026, 1, 15, 12) do
        expect(
          described_class.earliest_date_to_check
        ).to eq(Date.new(2025, 11, 15))
      end
    end

    it "uses the last available day when the previous month is shorter" do
      travel_to Time.zone.local(2026, 4, 30, 12) do
        expect(
          described_class.earliest_date_to_check
        ).to eq(Date.new(2026, 2, 28))
      end
    end

    it "passes on a PAYE reference without a name or address" do
      check = check_for(
        setting_paye_reference: "123/AB456",
        employments: [{"employer" => {"payeReference" => "123/AB456"}}]
      )

      expect(check.passed?).to be(true)
      expect(check.result.check).to eq(:employer_paye_reference)
    end

    it "prioritises a later PAYE match over an earlier name and postcode match" do
      check = check_for(
        setting_paye_reference: "123/AB456",
        employments: [
          employment,
          employment(name: "Unrelated employer", postcode: "XX1 1XX", paye_reference: "123/AB456")
        ]
      )
      expect(Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentChecks::NamePostcode).not_to receive(:new)

      expect(check.passed?).to be(true)
      expect(check.result.check).to eq(:employer_paye_reference)
    end

    it "falls back to name and postcode when PAYE references differ" do
      check = check_for(
        setting_paye_reference: "123/AB456",
        employments: [employment(paye_reference: "999/ZZ999")]
      )

      expect(check.passed?).to be(true)
      expect(check.result.check).to eq(:name_postcode)
    end

    it "fails when neither the PAYE reference nor name and postcode match" do
      check = check_for(
        setting_paye_reference: "123/AB456",
        employments: [employment(name: "Willow Grove", paye_reference: "999/ZZ999")]
      )

      expect(check.passed?).to be(false)
      expect(check.result.check).to be_nil
      expect(check.result.failure_reason).to eq(:no_matching_employment)
    end

    it "does not use a PAYE match from an unsuccessful response" do
      check = check_for(
        setting_paye_reference: "123/AB456",
        employments: [employment(paye_reference: "123/AB456")],
        status: 500
      )

      expect(check.passed?).to be(false)
      expect(check.result.check).to be_nil
    end

    it "fails without falling back even when another employment matches name and postcode" do
      setting = create(
        :eligible_eytfi_provider, name: "Oak Tree Nursery", postcode: "SW1A 1AA",
        paye_reference: "123/AB456", registered_person_name: "Oak Group",
        multiple_nurseries: true, eligible: true
      )
      create(
        :eligible_eytfi_provider, file_upload: setting.file_upload,
        registered_person_name: "Oak Group", eligible: false,
        paye_reference: "999/ZZ999"
      )
      check = described_class.new(
        setting: setting, hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            employment,
            employment(name: "Other Employer", postcode: "XX1 1XX", paye_reference: "123/AB456")
          ]
        }.to_json
      )
      expect(Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentChecks::NamePostcode).not_to receive(:new)

      expect(check.passed?).to be(false)
      expect(check.result.passed?).to be(false)
      expect(check.result.check).to eq(:employer_paye_reference)
      expect(check.result.failure_reason).to eq(:registered_person_has_ineligible_nurseries)
    end

    it "still uses name and postcode when the PAYE reference does not match" do
      setting = create(
        :eligible_eytfi_provider, name: "Oak Tree Nursery", postcode: "SW1A 1AA",
        paye_reference: "123/AB456", registered_person_name: "Oak Group",
        multiple_nurseries: true
      )
      create(
        :eligible_eytfi_provider, file_upload: setting.file_upload,
        registered_person_name: "Oak Group", eligible: false
      )
      check = described_class.new(
        setting: setting, hmrc_response_status: 200,
        hmrc_response_body: {employments: [employment(paye_reference: "999/ZZ999")]}.to_json
      )

      expect(check.passed?).to be(true)
      expect(check.result.check).to eq(:name_postcode)
      expect(check.result.failure_reason).to be_nil
    end

    it "rejects an unsuccessful response even when its body matches" do
      check = check_for(
        status: 500
      )

      expect(check.passed?).to be(false)
    end

    it "rejects a response whose status has not arrived" do
      check = check_for(
        status: nil
      )

      expect(check.passed?).to be(false)
    end

    it "rejects malformed JSON" do
      check = check_for(
        body: "{"
      )

      expect(check.passed?).to be(false)
    end

    it "rejects a blank response body" do
      check = check_for(
        body: ""
      )

      expect(check.passed?).to be(false)
    end

    it "rejects a JSON array at the top level" do
      check = check_for(
        body: "[]"
      )

      expect(check.passed?).to be(false)
    end

    it "rejects JSON null" do
      check = check_for(
        body: "null"
      )

      expect(check.passed?).to be(false)
    end

    it "rejects a missing employments key" do
      check = check_for(
        body: "{}"
      )

      expect(check.passed?).to be(false)
    end

    it "rejects employments that is not an array" do
      check = check_for(
        body: {
          "employments" => {}
        }.to_json
      )

      expect(check.passed?).to be(false)
    end

    it "rejects an employment that is not an object" do
      check = check_for(
        employments: [
          nil
        ]
      )

      expect(check.passed?).to be(false)
    end

    it "rejects a missing employer" do
      check = check_for(
        employments: [
          {}
        ]
      )

      expect(check.passed?).to be(false)
    end

    it "rejects an employer that is not an object" do
      check = check_for(
        employments: [
          {
            "employer" => "Oak Tree Nursery"
          }
        ]
      )

      expect(check.passed?).to be(false)
    end

    it "returns names in the order supplied by HMRC" do
      check = check_for(
        employments: [
          employment(
            name: "Oak Ltd"
          ),
          employment(
            name: "Willow Ltd"
          )
        ]
      )

      expect(check.employer_names).to eq(["Oak Ltd", "Willow Ltd"])
    end

    it "returns no names for an invalid response" do
      check = check_for(
        body: "invalid"
      )

      expect(check.employer_names).to eq([])
    end
  end
end
