require "rails_helper"

RSpec.describe(
  Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentChecks::NamePostcode
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

  describe "#result" do
    it "passes for identical names and postcodes" do
      check = check_for

      expect(check.result.passed?).to be(true)
      expect(check.result.check).to eq(:name_postcode)
      expect(check.result.failure_reason).to be_nil
    end

    it "normalizes case, whitespace, commas, hyphens and straight and curly apostrophes" do
      check = check_for(
        employments: [
          employment(
            name: "  OAK’S-TREE, Nursery  ",
            postcode: " sw1a1aa "
          )
        ],
        setting_name: "Oak'sTree Nursery"
      )

      expect(check.result.passed?).to be(true)
    end

    it "removes all ignored words and the optional full stop" do
      check = check_for(
        employments: [
          employment(
            name: "Private Oak Day Tree Preschool Nursery Limited Ltd."
          )
        ]
      )

      expect(check.result.passed?).to be(true)
    end

    it "expands ampersands to and" do
      check = check_for(
        employments: [
          employment(
            name: "Oak & Tree Nursery"
          )
        ],
        setting_name: "Oak and Tree Nursery"
      )

      expect(check.result.passed?).to be(true)
    end

    it "expands at signs to at" do
      check = check_for(
        employments: [
          employment(
            name: "Oak @ Tree Nursery"
          )
        ],
        setting_name: "Oak at Tree Nursery"
      )

      expect(check.result.passed?).to be(true)
    end

    it "does not remove ignored words embedded in other words" do
      check = check_for(
        employments: [
          employment(
            name: "Daylight Nursery"
          )
        ],
        setting_name: "Light Nursery"
      )

      expect(check.result.passed?).to be(false)
      expect(check.result.check).to be_nil
      expect(check.result.failure_reason).to eq(:no_matching_employment)
    end

    it "passes at exactly the two thirds similarity threshold" do
      check = check_for(
        employments: [
          employment(
            name: "Oak"
          )
        ]
      )

      expect(check.result.passed?).to be(true)
    end

    it "rejects a name below the similarity threshold" do
      check = check_for(
        employments: [
          employment(
            name: "Oak Red Blue"
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "finds a shared subsequence across intervening words" do
      check = check_for(
        employments: [
          employment(
            name: "Red Oak Blue Tree"
          )
        ]
      )

      expect(check.result.passed?).to be(true)
    end

    it "rejects names with no shared words" do
      check = check_for(
        employments: [
          employment(
            name: "Willow Grove Nursery"
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects a missing postcode" do
      check = check_for(
        employments: [
          {
            "employer" => {
              "name" => "Oak Tree Nursery",
              "address" => {}
            }
          }
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects a missing address" do
      check = check_for(
        employments: [
          {
            "employer" => {
              "name" => "Oak Tree Nursery"
            }
          }
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects a null postcode" do
      check = check_for(
        employments: [
          employment(
            postcode: nil
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects a whitespace only postcode" do
      check = check_for(
        employments: [
          employment(
            postcode: "  "
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "passes when a later employment matches" do
      check = check_for(
        employments: [
          employment(
            name: "Willow Grove"
          ),
          employment
        ]
      )

      expect(check.result.passed?).to be(true)
    end

    it "rejects when no employment matches" do
      check = check_for(
        employments: [
          employment(
            name: "Willow Grove"
          ),
          employment(
            name: "Elm House"
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "does not combine name words across employments" do
      check = check_for(
        employments: [
          employment(
            name: "Oak Red Blue"
          ),
          employment(
            name: "Tree Green Yellow"
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "does not inspect employment dates in the returned history" do
      check = check_for(
        employments: [
          employment.merge(
            "employment" => {
              "startDate" => "2000-01-01",
              "endDate" => "2000-02-01"
            }
          )
        ]
      )

      expect(check.result.passed?).to be(true)
    end

    it "rejects an empty employment history" do
      check = check_for(
        employments: []
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects a missing employer name" do
      check = check_for(
        employments: [
          {
            "employer" => {
              "address" => {
                "postcode" => "SW1A 1AA"
              }
            }
          }
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects a blank employer name" do
      check = check_for(
        employments: [
          employment(
            name: "  "
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects identical names made entirely of ignored words" do
      check = check_for(
        setting_name: "Private Day Nursery Ltd",
        employments: [
          employment(
            name: "Private Day Nursery Ltd"
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects the same two meaningful words in reversed order" do
      check = check_for(
        employments: [
          employment(
            name: "Tree Oak Nursery"
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "passes a different branch name when two of three meaningful words agree" do
      check = check_for(
        setting_name: "Oak Tree North Nursery",
        employments: [
          employment(
            name: "Oak Tree South Nursery"
          )
        ]
      )

      expect(check.result.passed?).to be(true)
    end

    it "rejects repeated words that dilute an otherwise identical name" do
      check = check_for(
        employments: [
          employment(
            name: "Oak Oak Oak Oak Tree Nursery"
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects a full stop on a meaningful word" do
      check = check_for(
        setting_name: "Oak Nursery",
        employments: [
          employment(
            name: "Oak. Nursery"
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "rejects a hyphen used as a word separator because it joins the words" do
      check = check_for(
        employments: [
          employment(
            name: "Oak-Tree Nursery"
          )
        ]
      )

      expect(check.result.passed?).to be(false)
    end

    it "passes a matching employment when another employer name is missing" do
      check = check_for(
        employments: [
          employment(name: nil),
          employment
        ]
      )

      expect(check.result.passed?).to be(true)
      expect(check.result.check).to eq(:name_postcode)
    end
  end
end
