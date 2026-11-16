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
    setting_paye_references: nil,
    setting_multiple_nurseries: nil
  )
    setting = build(
      :eligible_eytfi_provider,
      name: setting_name,
      postcode: setting_postcode,
      paye_references: Array(setting_paye_references),
      multiple_nurseries: setting_multiple_nurseries
    )
    described_class.new(setting: setting, employments: employments)
  end

  describe "#usable? and #result" do
    it "matches PAYE references ignoring case and whitespace", :aggregate_failures do
      [
        ["475hb32613", "475HB32613"],
        ["475HB32613", "475hb32613"],
        [" 475\tHB\n32613\r ", "475HB32613"],
        ["475HB32613", " 475\tHB\n32613\r "],
        ["475 hb32613", "475\u00a0Hb32613"]
      ].each do |nursery_reference, hmrc_reference|
        check = check_for(
          setting_paye_references: ["999/ZZ999", nursery_reference],
          employments: [employment(paye_reference: hmrc_reference)]
        )

        aggregate_failures("#{nursery_reference.inspect} against #{hmrc_reference.inspect}") do
          expect(check.usable?).to be(true)
          expect(check.result).to have_attributes(passed?: true)
        end
      end
    end

    it "does not match references that are empty after removing whitespace" do
      check = check_for(
        setting_paye_references: [nil, "", "\t\n\r"],
        employments: [employment(paye_reference: "\u00a0\t")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    ["475HB32613", "9612701970"].each do |reference|
      it "matches nursery PAYE reference #{reference}" do
        check = check_for(
          setting_paye_references: ["475HB32613", "9612701970"],
          employments: [employment(paye_reference: reference)]
        )

        expect(check.usable?).to be(true)
        expect(check.result.passed?).to be(true)
      end
    end

    it "does not match a substring of a nursery PAYE reference" do
      check = check_for(
        setting_paye_references: ["475HB32613", "9612701970"],
        employments: [employment(paye_reference: "475HB")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "is unusable when there are no employments" do
      check = check_for(setting_paye_references: "123/AB456", employments: [])

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "matches a later PAYE reference without requiring employer names or addresses" do
      check = check_for(
        setting_paye_references: "123/AB456",
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
        setting_paye_references: "123/AB456",
        employments: [employment(paye_reference: "999/ZZ999")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "fails a matching PAYE reference when the registered person has an ineligible nursery" do
      setting = create(
        :eligible_eytfi_provider, paye_references: ["123/AB456"],
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
        setting_paye_references: "",
        employments: [employment(name: "Willow Grove", paye_reference: "")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "does not match whitespace only PAYE references" do
      check = check_for(
        setting_paye_references: " ",
        employments: [employment(name: "Willow Grove", paye_reference: " ")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "does not match when HMRC omits the PAYE reference" do
      check = check_for(
        setting_paye_references: "123/AB456",
        employments: [employment(name: "Willow Grove")]
      )

      expect(check.usable?).to be(false)
      expect(check.result).to be_nil
    end

    it "fails for an ineligible companion when the multiple flag is false" do
      setting = create(
        :eligible_eytfi_provider, paye_references: ["123/AB456"],
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
      expect(check.result.passed?).to be(false)
      expect(check.result.check).to eq(:employer_paye_reference)
      expect(check.result.failure_reason).to eq(
        :registered_person_has_ineligible_nurseries
      )
    end

    it "fails for an ineligible companion when the multiple flag is unset" do
      setting = create(
        :eligible_eytfi_provider, paye_references: ["123/AB456"],
        registered_person_name: "Oak Group", multiple_nurseries: nil
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
      expect(check.result.failure_reason).to eq(
        :registered_person_has_ineligible_nurseries
      )
    end

    it "does not group nurseries with missing registered person names" do
      setting = create(
        :eligible_eytfi_provider,
        paye_references: ["123/AB456"],
        registered_person_name: nil
      )
      create(
        :eligible_eytfi_provider,
        file_upload: setting.file_upload,
        registered_person_name: nil,
        eligible: false
      )
      check = described_class.new(
        setting: setting,
        employments: [employment(paye_reference: "123/AB456")]
      )

      expect(check.result.passed?).to be(true)
      expect(check.result.failure_reason).to be_nil
    end

    it "passes when all nurseries for the registered person are eligible" do
      setting = create(
        :eligible_eytfi_provider, paye_references: ["123/AB456"], eligible: true,
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

    it "passes when the registered person has only one eligible nursery" do
      setting = create(
        :eligible_eytfi_provider, paye_references: ["123/AB456"], eligible: true,
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
        :eligible_eytfi_provider, paye_references: ["123/AB456"], eligible: true,
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
