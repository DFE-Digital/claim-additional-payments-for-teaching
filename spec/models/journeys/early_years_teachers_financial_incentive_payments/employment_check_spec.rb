require "rails_helper"

RSpec.describe(
  Journeys::EarlyYearsTeachersFinancialIncentivePayments::EmploymentCheck
) do
  def employment(
    name: "Oak Tree Nursery",
    postcode: "SW1A 1AA"
  )
    {
      "employer" => {
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
    status: 200,
    body: nil
  )
    setting = build(
      :eligible_eytfi_provider,
      name: setting_name,
      postcode: setting_postcode
    )
    described_class.new(
      setting: setting,
      hmrc_response_status: status,
      hmrc_response_body: body || {
        "employments" => employments
      }.to_json
    )
  end

  describe ".earliest_date_to_check" do
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
  end

  describe "#passed?" do
    it "passes for identical names and postcodes" do
      check = check_for

      expect(check.passed?).to be(true)
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

      expect(check.passed?).to be(true)
    end

    it "removes all ignored words and the optional full stop" do
      check = check_for(
        employments: [
          employment(
            name: "Private Oak Day Tree Preschool Nursery Limited Ltd."
          )
        ]
      )

      expect(check.passed?).to be(true)
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

      expect(check.passed?).to be(true)
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

      expect(check.passed?).to be(true)
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

      expect(check.passed?).to be(false)
    end

    it "passes at exactly the two thirds similarity threshold" do
      check = check_for(
        employments: [
          employment(
            name: "Oak"
          )
        ]
      )

      expect(check.passed?).to be(true)
    end

    it "rejects a name below the similarity threshold" do
      check = check_for(
        employments: [
          employment(
            name: "Oak Red Blue"
          )
        ]
      )

      expect(check.passed?).to be(false)
    end

    it "finds a shared subsequence across intervening words" do
      check = check_for(
        employments: [
          employment(
            name: "Red Oak Blue Tree"
          )
        ]
      )

      expect(check.passed?).to be(true)
    end

    it "rejects names with no shared words" do
      check = check_for(
        employments: [
          employment(
            name: "Willow Grove Nursery"
          )
        ]
      )

      expect(check.passed?).to be(false)
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

      expect(check.passed?).to be(false)
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

      expect(check.passed?).to be(false)
    end

    it "rejects a null postcode" do
      check = check_for(
        employments: [
          employment(
            postcode: nil
          )
        ]
      )

      expect(check.passed?).to be(false)
    end

    it "rejects a whitespace only postcode" do
      check = check_for(
        employments: [
          employment(
            postcode: "  "
          )
        ]
      )

      expect(check.passed?).to be(false)
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

      expect(check.passed?).to be(true)
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

      expect(check.passed?).to be(false)
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

      expect(check.passed?).to be(false)
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

      expect(check.passed?).to be(true)
    end

    it "rejects an empty employment history" do
      check = check_for(
        employments: []
      )

      expect(check.passed?).to be(false)
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

      expect(check.passed?).to be(false)
    end

    it "rejects a nonstring employer name" do
      check = check_for(
        employments: [
          employment(
            name: 123
          )
        ]
      )

      expect(check.passed?).to be(false)
    end

    it "rejects a blank employer name" do
      check = check_for(
        employments: [
          employment(
            name: "  "
          )
        ]
      )

      expect(check.passed?).to be(false)
    end
  end

  describe "#employer_names" do
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

  describe "adversarial examples documenting current behavior" do
    it "rejects identical names made entirely of ignored words" do
      check = check_for(
        setting_name: "Private Day Nursery Ltd",
        employments: [
          employment(
            name: "Private Day Nursery Ltd"
          )
        ]
      )

      expect(check.passed?).to be(false)
    end

    it "rejects the same two meaningful words in reversed order" do
      check = check_for(
        employments: [
          employment(
            name: "Tree Oak Nursery"
          )
        ]
      )

      expect(check.passed?).to be(false)
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

      expect(check.passed?).to be(true)
    end

    it "rejects repeated words that dilute an otherwise identical name" do
      check = check_for(
        employments: [
          employment(
            name: "Oak Oak Oak Oak Tree Nursery"
          )
        ]
      )

      expect(check.passed?).to be(false)
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

      expect(check.passed?).to be(false)
    end

    it "rejects a hyphen used as a word separator because it joins the words" do
      check = check_for(
        employments: [
          employment(
            name: "Oak-Tree Nursery"
          )
        ]
      )

      expect(check.passed?).to be(false)
    end

    it "rejects a valid matching employment when another entry is malformed" do
      check = check_for(
        employments: [
          employment,
          {
            "employer" => {
              "name" => nil
            }
          }
        ]
      )

      expect(check.passed?).to be(false)
    end
  end
end
