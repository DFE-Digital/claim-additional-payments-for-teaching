require "rails_helper"

RSpec.describe Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck do
  describe "#passed?" do
    it "does not pass a partial name match worth only 50 points" do
      nursery = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery"
      )

      check = described_class.new(
        setting: nursery,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Childcare"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "does not pass 98 points from a partial name and all address lines and town" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery",
        address_line_1: "1 High Street",
        address_line_2: "Village",
        address_line_3: "District",
        town: "Bristol"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Childcare",
                address: {
                  line1: "1 HIGH STREET",
                  line2: "Village",
                  line3: "District",
                  line4: "Bristol"
                }
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "does not pass matching addresses when the names do not match" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery",
        address_line_1: "1 High Street",
        address_line_2: "Village",
        address_line_3: "District",
        town: "Bristol"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Other Nursery",
                address: {
                  line1: "1 High Street",
                  line2: "Village",
                  line3: "District",
                  line4: "Bristol",
                  postcode: setting.postcode
                }
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "normalizes case and punctuation in postcode comparisons" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery",
        postcode: "EC1N 2TD"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Childcare",
                address: {
                  postcode: " ec1n 2td.,- "
                }
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "does not combine scores from different employments" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Childcare"
              }
            },
            {
              employer: {
                name: "Springfield Group"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "passes an exact name match without address or employment dates" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Nursery"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "ignores case, surrounding spaces and Ltd. in names" do
      setting = build(
        :eligible_eytfi_provider,
        name: "  SPRINGFIELD Nursery Ltd.  "
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "springfield nursery"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "removes Ltd from company names" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery Ltd"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Nursery"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "removes Limited from company names" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Nursery Limited"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "passes at 100 points when the postcode matches and the employer name contains the setting name's first word" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery",
        postcode: "EC1N 2TD"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "The Springfield Childcare Group",
                address: {
                  postcode: "EC1N 2TD"
                }
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "passes at 100 points when the postcode matches and the setting name contains the employer name's first word" do
      setting = build(
        :eligible_eytfi_provider,
        name: "The Springfield Nursery",
        postcode: "EC1N 2TD"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Childcare",
                address: {
                  postcode: "EC1N 2TD"
                }
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "matches first words as substrings as in the VB rules" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Spring Nursery"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Childcare",
                address: {
                  postcode: "EC1N 2TD"
                }
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "does not match names that share only a later word" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Other Nursery"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "does not pass a blank setting name" do
      setting = build(
        :eligible_eytfi_provider,
        name: "  "
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Nursery"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "does not match a setting name consisting only of a company suffix" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Limited"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Springfield Nursery"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "does not match an employer name consisting only of a company suffix" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Ltd."
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "does not pass an unsuccessful response even when the employer matches" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 500,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: setting.name
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "does not pass invalid JSON" do
      setting = build(
        :eligible_eytfi_provider
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: "not JSON"
      )

      expect(check.passed?).to eq(false)
    end

    it "does not pass a missing response body" do
      setting = build(
        :eligible_eytfi_provider
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: nil
      )

      expect(check.passed?).to eq(false)
    end

    it "does not pass an empty employment history" do
      setting = build(
        :eligible_eytfi_provider
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: []
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "does not pass a response without an employments array" do
      setting = build(
        :eligible_eytfi_provider
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: {
            employer: {
              name: "Springfield Nursery"
            }
          }
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end

    it "rejects malformed employment records even alongside a matching employer" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Springfield Nursery"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: setting.name
              }
            },
            {
              employer: nil
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(false)
    end
  end

  describe "#employer_names" do
    it "preserves the original employer names for admin notes" do
      setting = build(
        :eligible_eytfi_provider
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "SPRINGFIELD Nursery Ltd."
              }
            },
            {
              employer: {
                name: "Other Nursery Limited"
              }
            }
          ]
        }.to_json
      )

      expect(check.employer_names).to eq(["SPRINGFIELD Nursery Ltd.", "Other Nursery Limited"])
    end
  end

  describe "pathological matching outcomes" do
    it "passes an exact name match with repeated whitespace even without an address" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Little Acorns Nursery"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Little  Acorns\tNursery Limited"
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "passes a partial name match when the postcode differs only in whitespace" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Little Acorns Nursery",
        postcode: "BS8 1AA"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Little Acorns Childcare",
                address: {
                  postcode: "BS81AA"
                }
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end

    it "passes the correct nursery when only name and postcode spacing differ" do
      setting = build(
        :eligible_eytfi_provider,
        name: "Little Acorns Nursery",
        address_line_1: "1 High Street",
        address_line_2: "Clifton",
        address_line_3: "Avon",
        town: "Bristol",
        postcode: "BS8 1AA"
      )

      check = described_class.new(
        setting: setting,
        hmrc_response_status: 200,
        hmrc_response_body: {
          employments: [
            {
              employer: {
                name: "Little  Acorns Nursery",
                address: {
                  line1: "1 High Street",
                  line2: "Clifton",
                  line3: "Avon",
                  line4: "Bristol",
                  postcode: "BS81AA"
                }
              }
            }
          ]
        }.to_json
      )

      expect(check.passed?).to eq(true)
    end
  end
end
