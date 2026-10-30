require "rails_helper"

RSpec.describe(
  Journeys::EarlyYearsTeachersFinancialIncentivePayments::
    EmploymentChecks::RegisteredPerson
) do
  it "passes eligible groups ignoring case and surrounding whitespace" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )
    create(
      :eligible_eytfi_provider, file_upload: setting.file_upload,
      registered_person_name: "  OAK GROUP  ", eligible: true
    )

    check = described_class.new(
      setting: setting,
      employments: [{"employer" => {"name" => "  oak group  "}}]
    )

    expect(check.usable?).to be(true)
    expect(check.result.check).to eq(:registered_person)
    expect(check.result.passed?).to be(true)
    expect(check.result.failure_reason).to be_nil
  end

  it "fails when any nursery for the registered person is ineligible" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )
    create(
      :eligible_eytfi_provider, file_upload: setting.file_upload,
      registered_person_name: " oak group ", eligible: false
    )

    check = described_class.new(
      setting: setting,
      employments: [{"employer" => {"name" => "OAK GROUP"}}]
    )

    expect(check.usable?).to be(true)
    expect(check.result.passed?).to be(false)
    expect(check.result.check).to eq(:registered_person)
    expect(check.result.failure_reason).to eq(
      :registered_person_has_ineligible_nurseries
    )
  end

  it "fails when an eligible registered person differs from the setting" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )
    create(
      :eligible_eytfi_provider, file_upload: setting.file_upload,
      registered_person_name: "Willow Group", eligible: true
    )

    check = described_class.new(
      setting: setting,
      employments: [{"employer" => {"name" => "Willow Group"}}]
    )

    expect(check.usable?).to be(true)
    expect(check.result.passed?).to be(false)
    expect(check.result.failure_reason).to eq(
      :registered_person_does_not_match_setting
    )
  end

  it "checks the chosen setting before group eligibility" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )
    create(
      :eligible_eytfi_provider, file_upload: setting.file_upload,
      registered_person_name: "Willow Group", eligible: false
    )

    check = described_class.new(
      setting: setting,
      employments: [{"employer" => {"name" => "  WILLOW GROUP  "}}]
    )

    expect(check.usable?).to be(true)
    expect(check.result.check).to eq(:registered_person)
    expect(check.result.passed?).to be(false)
    expect(check.result.failure_reason).to eq(
      :registered_person_does_not_match_setting
    )
  end

  it "is unusable when no registered person matches" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )

    check = described_class.new(
      setting: setting,
      employments: [{"employer" => {"name" => "Unknown Group"}}]
    )

    expect(check.usable?).to be(false)
    expect(check.result).to be_nil
  end

  it "is unusable for missing and blank HMRC names" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )

    check = described_class.new(
      setting: setting,
      employments: [
        {"employer" => {"name" => nil}},
        {"employer" => {"name" => ""}},
        {"employer" => {"name" => "   "}}
      ]
    )

    expect(check.usable?).to be(false)
    expect(check.result).to be_nil
  end

  it "is unusable when nursery registered person names are blank" do
    setting = create(:eligible_eytfi_provider, registered_person_name: nil)
    create(
      :eligible_eytfi_provider,
      file_upload: setting.file_upload,
      registered_person_name: "  "
    )

    check = described_class.new(
      setting: setting,
      employments: [
        {"employer" => {"name" => nil}},
        {"employer" => {"name" => ""}},
        {"employer" => {"name" => "  "}},
        {"employer" => {"name" => "Unknown Group"}}
      ]
    )

    expect(check.usable?).to be(false)
    expect(check.result).to be_nil
  end

  it "fails when the chosen setting has no registered person name" do
    setting = create(:eligible_eytfi_provider, registered_person_name: nil)
    create(
      :eligible_eytfi_provider, file_upload: setting.file_upload,
      registered_person_name: "Oak Group", eligible: true
    )

    check = described_class.new(
      setting: setting,
      employments: [{"employer" => {"name" => "Oak Group"}}]
    )

    expect(check.usable?).to be(true)
    expect(check.result.passed?).to be(false)
    expect(check.result.failure_reason).to eq(
      :registered_person_does_not_match_setting
    )
  end

  it "ignores matching registered people in another upload" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )
    create(
      :eligible_eytfi_provider, file_upload: create(:file_upload),
      registered_person_name: "Willow Group", eligible: true
    )

    check = described_class.new(
      setting: setting,
      employments: [{"employer" => {"name" => "Willow Group"}}]
    )

    expect(check.usable?).to be(false)
    expect(check.result).to be_nil
  end

  it "ignores ineligible nurseries in another upload" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )
    create(
      :eligible_eytfi_provider, file_upload: create(:file_upload),
      registered_person_name: "Oak Group", eligible: false
    )

    check = described_class.new(
      setting: setting,
      employments: [{"employer" => {"name" => "Oak Group"}}]
    )

    expect(check.usable?).to be(true)
    expect(check.result.check).to eq(:registered_person)
    expect(check.result.passed?).to be(true)
    expect(check.result.failure_reason).to be_nil
  end

  it "passes when only the later employment matches the setting" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )
    create(
      :eligible_eytfi_provider, file_upload: setting.file_upload,
      registered_person_name: "Willow Group", eligible: false
    )

    check = described_class.new(
      setting: setting,
      employments: [
        {"employer" => {"name" => "Willow Group"}},
        {"employer" => {"name" => "Oak Group"}}
      ]
    )

    expect(check.usable?).to be(true)
    expect(check.result.check).to eq(:registered_person)
    expect(check.result.passed?).to be(true)
    expect(check.result.failure_reason).to be_nil
  end

  it "passes when only the earlier employment matches the setting" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )
    create(
      :eligible_eytfi_provider, file_upload: setting.file_upload,
      registered_person_name: "Willow Group", eligible: false
    )

    check = described_class.new(
      setting: setting,
      employments: [
        {"employer" => {"name" => "Oak Group"}},
        {"employer" => {"name" => "Willow Group"}}
      ]
    )

    expect(check.usable?).to be(true)
    expect(check.result.check).to eq(:registered_person)
    expect(check.result.passed?).to be(true)
    expect(check.result.failure_reason).to be_nil
  end

  it "is unusable without employments" do
    setting = create(
      :eligible_eytfi_provider,
      registered_person_name: "Oak Group",
      eligible: true
    )

    check = described_class.new(
      setting: setting,
      employments: []
    )

    expect(check.usable?).to be(false)
    expect(check.result).to be_nil
  end
end
