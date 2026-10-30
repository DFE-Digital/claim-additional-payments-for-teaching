require "rails_helper"

RSpec.describe(
  Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentChecks::PayeReference
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
    setting_multiple_nurseries: nil
  )
    setting = build(
      :eligible_eytfi_provider,
      name: setting_name,
      postcode: setting_postcode,
      paye_reference: setting_paye_reference,
      multiple_nurseries: setting_multiple_nurseries
    )
    described_class.new(setting: setting, employments: employments)
  end

  describe "#usable? and #result" do
    it "is unusable when there are no employments" do
      check = check_for(setting_paye_reference: "123/AB456", employments: [])

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "matches a later PAYE reference without requiring employer names or addresses" do
      check = check_for(
        setting_paye_reference: "123/AB456",
        employments: [
          {"employer" => {"payeReference" => "999/ZZ999"}},
          {"employer" => {"payeReference" => "123/AB456"}}
        ]
      )

      expect(check.usable?).to be(true)
      expect(check.result.passed?).to be(true)
      expect(check.result.check).to eq(:employer_paye_reference)
      expect(check.result.failure_reason).to be_nil
    end

    it "does not match a different PAYE reference" do
      check = check_for(
        setting_paye_reference: "123/AB456",
        employments: [employment(paye_reference: "999/ZZ999")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "fails a matching PAYE reference when the registered person has an ineligible nursery" do
      setting = create(
        :eligible_eytfi_provider, paye_reference: "123/AB456",
        registered_person_name: "Oak Group", multiple_nurseries: true
      )
      create(
        :eligible_eytfi_provider, file_upload: setting.file_upload,
        registered_person_name: "Oak Group", eligible: false
      )
      check = described_class.new(
        setting: setting, employments: [employment(paye_reference: "123/AB456")]
      )

      expect(check.usable?).to be(true)
      expect(check.result.passed?).to be(false)
      expect(check.result.check).to eq(:employer_paye_reference)
      expect(check.result.failure_reason).to eq(:registered_person_has_ineligible_nurseries)
    end

    it "does not match nil PAYE references" do
      check = check_for(employments: [employment(name: "Willow Grove")])

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "does not match empty PAYE references" do
      check = check_for(
        setting_paye_reference: "",
        employments: [employment(name: "Willow Grove", paye_reference: "")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "does not match whitespace only PAYE references" do
      check = check_for(
        setting_paye_reference: " ",
        employments: [employment(name: "Willow Grove", paye_reference: " ")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "does not match when HMRC omits the PAYE reference" do
      check = check_for(
        setting_paye_reference: "123/AB456",
        employments: [employment(name: "Willow Grove")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "passes when the setting does not control multiple nurseries" do
      setting = create(
        :eligible_eytfi_provider, paye_reference: "123/AB456",
        registered_person_name: "Oak Group", multiple_nurseries: false
      )
      create(
        :eligible_eytfi_provider, file_upload: setting.file_upload,
        registered_person_name: "Oak Group", eligible: false
      )
      check = described_class.new(
        setting: setting, employments: [employment(paye_reference: "123/AB456")]
      )

      expect(check.usable?).to be(true)
      expect(check.result.passed?).to be(true)
      expect(check.result.check).to eq(:employer_paye_reference)
      expect(check.result.failure_reason).to be_nil
    end

    it "passes when all nurseries for the registered person are eligible" do
      setting = create(
        :eligible_eytfi_provider, paye_reference: "123/AB456", eligible: true,
        registered_person_name: "Oak Group", multiple_nurseries: true
      )
      create(
        :eligible_eytfi_provider, file_upload: setting.file_upload,
        registered_person_name: "Oak Group", eligible: true
      )
      create(
        :eligible_eytfi_provider, file_upload: setting.file_upload,
        registered_person_name: "Other Group", eligible: false
      )
      check = described_class.new(
        setting: setting, employments: [employment(paye_reference: "123/AB456")]
      )

      expect(check.usable?).to be(true)
      expect(check.result.passed?).to be(true)
      expect(check.result.check).to eq(:employer_paye_reference)
      expect(check.result.failure_reason).to be_nil
    end

    it "passes with multiple nurseries flagged when only one setting is recorded pending product review" do
      setting = create(
        :eligible_eytfi_provider, paye_reference: "123/AB456", eligible: true,
        registered_person_name: "Oak Group", multiple_nurseries: true
      )
      check = described_class.new(
        setting: setting, employments: [employment(paye_reference: "123/AB456")]
      )

      expect(check.usable?).to be(true)
      expect(check.result.passed?).to be(true)
      expect(check.result.check).to eq(:employer_paye_reference)
      expect(check.result.failure_reason).to be_nil
    end

    it "ignores ineligible records from other upload versions" do
      setting = create(
        :eligible_eytfi_provider, paye_reference: "123/AB456", eligible: true,
        registered_person_name: "Oak Group", multiple_nurseries: true
      )
      other_upload = create(:file_upload)
      create(
        :eligible_eytfi_provider, file_upload: other_upload,
        registered_person_name: "Oak Group", eligible: false
      )
      check = described_class.new(
        setting: setting, employments: [employment(paye_reference: "123/AB456")]
      )

      expect(check.usable?).to be(true)
      expect(check.result.passed?).to be(true)
    end
  end
end
