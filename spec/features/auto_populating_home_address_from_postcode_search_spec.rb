require "rails_helper"

RSpec.feature "Teacher claiming Early-Career Payments uses the address auto-population" do
  before do
    body_results_for_postcode_so16_9fx = <<-RESULTS_SO16__9FX
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
    RESULTS_SO16__9FX

    stub_request(:get, "https://api.os.uk/search/places/v1/postcode?key=api-key-value&postcode=SO169FX")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "Expect" => "",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus"
        }
      ).to_return(status: 200, body: body_results_for_postcode_so16_9fx, headers: {})

    body_results_for_postcode_se13_7un = <<-RESULTS_SE13__7UN
      {
        "header" : {
          "uri" : "https://api.os.uk/search/places/v1/postcode?postcode=SE137UN",
          "query" : "postcode=SE137UN",
          "offset" : 0,
          "totalresults" : 33,
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
              "UPRN" : "100022018435",
              "UDPRN" : "21645238",
              "ADDRESS" : "4, WEARSIDE ROAD, LONDON, SE13 7UN",
              "BUILDING_NUMBER" : "4",
              "THOROUGHFARE_NAME" : "WEARSIDE ROAD",
              "POST_TOWN" : "LONDON",
              "POSTCODE" : "SE13 7UN",
              "RPC" : "1",
              "X_COORDINATE" : 537915.0,
              "Y_COORDINATE" : 174996.0,
              "STATUS" : "APPROVED",
              "LOGICAL_STATUS_CODE" : "1",
              "CLASSIFICATION_CODE" : "RD04",
              "CLASSIFICATION_CODE_DESCRIPTION" : "Terraced",
              "LOCAL_CUSTODIAN_CODE" : 5690,
              "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "LEWISHAM",
              "POSTAL_ADDRESS_CODE" : "D",
              "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
              "BLPU_STATE_CODE" : null,
              "BLPU_STATE_CODE_DESCRIPTION" : "Unknown/Not applicable",
              "TOPOGRAPHY_LAYER_TOID" : "osgb1000041787221",
              "LAST_UPDATE_DATE" : "10/02/2016",
              "ENTRY_DATE" : "15/09/2001",
              "LANGUAGE" : "EN",
              "MATCH" : 1.0,
              "MATCH_DESCRIPTION" : "EXACT"
            }
          },
          {
            "DPA" : {
              "UPRN" : "100022018436",
              "UDPRN" : "21645239",
              "ADDRESS" : "5, WEARSIDE ROAD, LONDON, SE13 7UN",
              "BUILDING_NUMBER" : "5",
              "THOROUGHFARE_NAME" : "WEARSIDE ROAD",
              "POST_TOWN" : "LONDON",
              "POSTCODE" : "SE13 7UN",
              "RPC" : "2",
              "X_COORDINATE" : 537939.0,
              "Y_COORDINATE" : 175028.0,
              "STATUS" : "APPROVED",
              "LOGICAL_STATUS_CODE" : "1",
              "CLASSIFICATION_CODE" : "RD04",
              "CLASSIFICATION_CODE_DESCRIPTION" : "Terraced",
              "LOCAL_CUSTODIAN_CODE" : 5690,
              "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "LEWISHAM",
              "POSTAL_ADDRESS_CODE" : "D",
              "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
              "BLPU_STATE_CODE" : null,
              "BLPU_STATE_CODE_DESCRIPTION" : "Unknown/Not applicable",
              "TOPOGRAPHY_LAYER_TOID" : "osgb1000041792607",
              "LAST_UPDATE_DATE" : "10/02/2016",
              "ENTRY_DATE" : "15/09/2001",
              "LANGUAGE" : "EN",
              "MATCH" : 1.0,
              "MATCH_DESCRIPTION" : "EXACT"
            }
          },
          {
            "DPA" : {
              "UPRN" : "100022018437",
              "UDPRN" : "21645240",
              "ADDRESS" : "6, WEARSIDE ROAD, LONDON, SE13 7UN",
              "BUILDING_NUMBER" : "6",
              "THOROUGHFARE_NAME" : "WEARSIDE ROAD",
              "POST_TOWN" : "LONDON",
              "POSTCODE" : "SE13 7UN",
              "RPC" : "1",
              "X_COORDINATE" : 537915.0,
              "Y_COORDINATE" : 175002.0,
              "STATUS" : "APPROVED",
              "LOGICAL_STATUS_CODE" : "1",
              "CLASSIFICATION_CODE" : "RD04",
              "CLASSIFICATION_CODE_DESCRIPTION" : "Terraced",
              "LOCAL_CUSTODIAN_CODE" : 5690,
              "LOCAL_CUSTODIAN_CODE_DESCRIPTION" : "LEWISHAM",
              "POSTAL_ADDRESS_CODE" : "D",
              "POSTAL_ADDRESS_CODE_DESCRIPTION" : "A record which is linked to PAF",
              "BLPU_STATE_CODE" : null,
              "BLPU_STATE_CODE_DESCRIPTION" : "Unknown/Not applicable",
              "TOPOGRAPHY_LAYER_TOID" : "osgb1000041792621",
              "LAST_UPDATE_DATE" : "10/02/2016",
              "ENTRY_DATE" : "15/09/2001",
              "LANGUAGE" : "EN",
              "MATCH" : 1.0,
              "MATCH_DESCRIPTION" : "EXACT"
            }
          }
        ]
      }
    RESULTS_SE13__7UN

    stub_request(:get, "https://api.os.uk/search/places/v1/postcode?key=api-key-value&postcode=SE137UN")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "Expect" => "",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus"
        }
      ).to_return(status: 200, body: body_results_for_postcode_se13_7un, headers: {})

    stub_request(:get, "https://api.os.uk/search/places/v1/postcode?key=api-key-value&postcode=DA15FZ")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "Expect" => "",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus"
        }
      ).to_return(status: 500, headers: {})
  end

  context "with a supplied postcode" do
    let(:journey_session) do
      Journeys::TargetedRetentionIncentivePayments::Session.order(:created_at).last
    end

    before do
      create(:journey_configuration, :targeted_retention_incentive_payments)
      start_targeted_retention_incentive_payments_claim

      journey_session.answers.assign_attributes(
        attributes_for(
          :targeted_retention_incentive_payments_answers,
          :submittable,
          address_line_1: nil,
          address_line_2: nil,
          address_line_3: nil,
          address_line_4: nil,
          postcode: nil
        )
      )
      journey_session.save!
    end

    scenario "with Ordnance Survey API data" do
      jump_to_claim_journey_page(
        slug: "postcode-search",
        journey_session: journey_session
      )

      # - What is your home address
      expect(page).to have_text("What is your home address?")

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text("What is your home address?")

      choose "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX"
      click_on "Continue"

      journey_session.reload
      answers = journey_session.answers
      expect(answers.address_line_1).to eql "Flat 11, Millbrook Tower"
      expect(answers.address_line_2).to eql "Windermere Avenue"
      expect(answers.address_line_3).to eql "Southampton"
      expect(answers.postcode).to eql "SO16 9FX"

      # - What is your address
      expect(page).not_to have_text("What is your address?")

      # - Email address
      expect(page).to have_text("Email address")
    end

    scenario "Claimant cannot find the correct address so chooses to manually enter address" do
      jump_to_claim_journey_page(
        slug: "postcode-search",
        journey_session: journey_session
      )

      # - What is your home address
      expect(page).to have_text("What is your home address?")

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text("SO16 9FX Change")
      expect(page).to have_text("What is your home address?")
      expect(page).to have_text("Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX")

      click_on("I can’t find my address in the list")

      # - What is your address
      expect(page).to have_text("What is your address?")

      fill_in "House number or name", with: "Penthouse Apartment, Millbrook Tower"
      fill_in "Building and street", with: "Windermere Avenue"
      fill_in "Town or city", with: "Southampton"
      fill_in "County", with: "Hampshire"
      fill_in "Postcode", with: "SO16 9FX"
      click_on "Continue"

      journey_session.reload
      answers = journey_session.answers
      expect(answers.address_line_1).to eql("Penthouse Apartment, Millbrook Tower")
      expect(answers.address_line_2).to eql("Windermere Avenue")
      expect(answers.address_line_3).to eql("Southampton")
      expect(answers.address_line_4).to eql("Hampshire")
      expect(answers.postcode).to eql("SO16 9FX")

      # - Email address
      expect(page).to have_text("Email address")
    end

    # Bugfix - did cause an exception after pressing back
    scenario "Claimant cannot find the correct address so chooses to manually enter address, presses back before filling anything to go to the postcode search again" do
      jump_to_claim_journey_page(
        slug: "postcode-search",
        journey_session: journey_session
      )

      # - What is your home address
      expect(page).to have_text("What is your home address?")

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text("SO16 9FX Change")
      expect(page).to have_text("What is your home address?")
      expect(page).to have_text("Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX")

      click_on("I can’t find my address in the list")
      click_link("Back")

      # - Redirects to a fresh postcode search
      expect(page).to have_text("What is your home address?")
    end

    scenario "Claimant decides they want to change the POSTCODE from the 'select-home-address' screen" do
      jump_to_claim_journey_page(
        slug: "postcode-search",
        journey_session: journey_session
      )

      # - What is your home address (1st time before making the request to change)
      expect(page).to have_text("What is your home address?")

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text("What is your home address?")
      expect(page).to have_text("Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX")

      click_on("Change")

      # - What is your home address - Back to make the requested change
      expect(page).not_to have_text("What is your address?")
      expect(page).to have_text("What is your home address?")

      expect(page).to have_field("Postcode", with: "SO16 9FX")

      fill_in "Postcode", with: "SE13 7UN"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text("What is your home address?")
      expect(page).to have_link("Back", href: claim_path(Journeys::TargetedRetentionIncentivePayments.routing_name, "postcode-search"))
      expect(page).to have_text("4, Wearside Road, London, SE13 7UN")
      expect(page).to have_text("5, Wearside Road, London, SE13 7UN")
      expect(page).to have_text("6, Wearside Road, London, SE13 7UN")

      choose "5, Wearside Road, London, SE13 7UN"
      click_on "Continue"

      journey_session.reload
      answers = journey_session.answers
      expect(answers.address_line_1).to eql("5")
      expect(answers.address_line_2).to eql("Wearside Road")
      expect(answers.address_line_3).to eql("London")
      expect(answers.postcode).to eql("SE13 7UN")

      # - What is your address
      expect(page).not_to have_text("What is your address?")

      # - Email address
      expect(page).to have_text("Email address")

      # Check postcode search field retains the user's last input if the address was saved on the claim
      click_link "Back" # -> select-home-address
      click_link "Back" # -> postcode-search

      expect(page).to have_field("Postcode", with: "SE13 7UN")
      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      click_link "Change"

      expect(page).to have_field("Postcode", with: "SO16 9FX")
    end

    context do
      scenario "Ordanance Survery Client raise a ResponseError" do
        jump_to_claim_journey_page(
          slug: "postcode-search",
          journey_session: journey_session
        )

        # - What is your home address
        expect(page).to have_text("What is your home address?")

        fill_in "Postcode", with: "DA1 5FZ"
        click_on "Search"

        # Redirects to manual address page
        expect(page).to have_text("What is your address?")

        # Shows a flash message to enter address manually
        expect(page).to have_text("Please enter your address manually")
      end
    end
  end
end
