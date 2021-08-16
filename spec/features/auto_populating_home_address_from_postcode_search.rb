require "rails_helper"

RSpec.feature "Teacher Early-Career Payments claims" do
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
  end

  context "Auto-populate address details with supplied postcode" do
    let(:claim) do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim.address_line_1 = nil
      claim.address_line_2 = nil
      claim.address_line_3 = nil
      claim.postcode = nil
      claim.save
      claim
    end

    scenario "with Ordnance Survey API data" do
      expect(claim.valid?(:submit)).to eq false
      visit claim_path(claim.policy.routing_name, "postcode-search")

      # - What is your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))

      choose "flat_11_millbrook_tower_windermere_avenue_southampton_so16_9fx"
      click_on "Continue"

      expect(claim.reload.address_line_1).to eql "Flat 11, Millbrook Tower"
      expect(claim.address_line_2).to eql "Windermere Avenue"
      expect(claim.address_line_3).to eql "Southampton"
      expect(claim.postcode).to eql "SO16 9FX"

      # - What is your address
      expect(page).not_to have_text(I18n.t("questions.address.generic.title"))

      # - Email address
      expect(page).to have_text(I18n.t("questions.email_address"))
    end

    scenario "Claimant cannot find the correct address so chooses to manually enter address" do
      expect(claim.valid?(:submit)).to eq false
      visit claim_path(claim.policy.routing_name, "postcode-search")

      # - What is your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_text("Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX")
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      click_link(I18n.t("questions.address.home.i_cannot_find"))

      # - What is your address
      expect(page).to have_text(I18n.t("questions.address.generic.title"))

      fill_in :claim_address_line_1, with: "Penthouse Apartment, Millbrook Tower"
      fill_in :claim_address_line_2, with: "Windermere Avenue"
      fill_in "Town or city", with: "Southampton"
      fill_in "Postcode", with: "SO16 9FX"
      click_on "Continue"

      expect(claim.reload.address_line_1).to eql("Penthouse Apartment, Millbrook Tower")
      expect(claim.address_line_2).to eql("Windermere Avenue")
      expect(claim.address_line_3).to eql("Southampton")
      expect(claim.postcode).to eql("SO16 9FX")

      # - Email address
      expect(page).to have_text(I18n.t("questions.email_address"))
    end

    scenario "Claimant decides they want to change the POSTCODE from the 'select-home-address' screen" do
      expect(claim.valid?(:submit)).to eq false
      visit claim_path(claim.policy.routing_name, "postcode-search")

      # - What is your home address (1st time before making the request to change)
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      fill_in "Postcode", with: "SO16 9FX"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link("Change", href: claim_path(EarlyCareerPayments.routing_name, "postcode-search"))
      expect(page).to have_text("Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX")
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      click_link("Change", href: claim_path(EarlyCareerPayments.routing_name, "postcode-search"))

      # - What is your home address - Back to make the requested change
      expect(page).not_to have_text(I18n.t("questions.address.generic.title"))
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      fill_in "Postcode", with: "SE13 7UN"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link("Change", href: claim_path(EarlyCareerPayments.routing_name, "postcode-search"))
      expect(page).to have_text("4, Wearside Road, London, SE13 7UN")
      expect(page).to have_text("5, Wearside Road, London, SE13 7UN")
      expect(page).to have_text("6, Wearside Road, London, SE13 7UN")
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      choose "5_wearside_road_london_se13_7un"
      click_on "Continue"

      expect(claim.reload.address_line_1).to eql("5")
      expect(claim.address_line_2).to eql("Wearside Road")
      expect(claim.address_line_3).to eql("London")
      expect(claim.postcode).to eql("SE13 7UN")

      # - What is your address
      expect(page).not_to have_text(I18n.t("questions.address.generic.title"))

      # - Email address
      expect(page).to have_text(I18n.t("questions.email_address"))
    end
  end

  context "Auto-populate address details with supplied postcode and door number" do
    before do
      body_results_for_searchable_postcode_and_address = <<-RESULTS_SE13__7UN_NO_38A
        {
          "header" : {
            "uri" : "https://api.os.uk/search/places/v1/find?maxresults=1&minmatch=0.4&query=22%2C%20SE137UN",
            "query" : "query=22, SE137UN",
            "offset" : 0,
            "totalresults" : 442229,
            "format" : "JSON",
            "dataset" : "DPA",
            "lr" : "EN,CY",
            "maxresults" : 1,
            "matchprecision" : 1,
            "epoch" : "85",
            "minmatch" : 0.4,
            "output_srs" : "EPSG:27700"
          },
          "results" : [ 
            {
              "DPA" : {
                "UPRN" : "100022018452",
                "UDPRN" : "21645224",
                "ADDRESS" : "38A, WEARSIDE ROAD, LONDON, SE13 7UN",
                "BUILDING_NUMBER" : "38A",
                "THOROUGHFARE_NAME" : "WEARSIDE ROAD",
                "POST_TOWN" : "LONDON",
                "POSTCODE" : "SE13 7UN",
                "RPC" : "1",
                "X_COORDINATE" : 537905.0,
                "Y_COORDINATE" : 175041.0,
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
                "TOPOGRAPHY_LAYER_TOID" : "osgb1000041792630",
                "LAST_UPDATE_DATE" : "10/02/2016",
                "ENTRY_DATE" : "15/09/2001",
                "LANGUAGE" : "EN",
                "MATCH" : 0.4,
                "MATCH_DESCRIPTION" : "NO MATCH"
              }
            } 
          ]
        }
      RESULTS_SE13__7UN_NO_38A

      stub_request(:get, "https://api.os.uk/search/places/v1/find?key=api-key-value&maxresults=1&minmatch=0.4&query=38A,%20SE137UN")
        .with(
          headers: {
            "Content-Type" => "application/json",
            "Expect" => "",
            "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus"
          }
        ).to_return(status: 200, body: body_results_for_searchable_postcode_and_address, headers: {})
    end

    let(:claim) do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim.address_line_1 = nil
      claim.address_line_2 = nil
      claim.address_line_3 = nil
      claim.postcode = nil
      claim.save
      claim
    end

    scenario "with Ordnance Survey API data" do
      expect(claim.valid?(:submit)).to eq false
      visit claim_path(claim.policy.routing_name, "postcode-search")

      # - What is your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      fill_in "Postcode", with: "SE13 7UN"
      fill_in "House number or name (optional)", with: "38A"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))

      choose "38a_wearside_road_london_se13_7un"
      click_on "Continue"

      expect(claim.reload.address_line_1).to eql "38A"
      expect(claim.address_line_2).to eql "Wearside Road"
      expect(claim.address_line_3).to eql "London"
      expect(claim.postcode).to eql "SE13 7UN"

      # - What is your address
      expect(page).not_to have_text(I18n.t("questions.address.generic.title"))

      # - Email address
      expect(page).to have_text(I18n.t("questions.email_address"))
    end
  end

  context "Auto-populate address details with supplied postcode and door number" do
    before do
      body_results_for_searchable_postcode_and_address_and_postcode_not_found = <<-RESULTS_SE13__7UN_NO_40_RESPONSE_NULL
        {
          "header" : {
            "uri" : "https://api.os.uk/search/places/v1/find?maxresults=1&minmatch=0.4&query=40%2C%20SE137UN",
            "query" : "query=40, SE137UN",
            "offset" : 0,
            "totalresults" : 248823,
            "format" : "JSON",
            "dataset" : "DPA",
            "lr" : "EN,CY",
            "maxresults" : 1,
            "matchprecision" : 1,
            "epoch" : "85",
            "minmatch" : 0.4,
            "output_srs" : "EPSG:27700"
          }
        }
      RESULTS_SE13__7UN_NO_40_RESPONSE_NULL

      stub_request(:get, "https://api.os.uk/search/places/v1/find?key=api-key-value&maxresults=1&minmatch=0.4&query=40,%20SE137UN")
        .with(
          headers: {
            "Content-Type" => "application/json",
            "Expect" => "",
            "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus"
          }
        ).to_return(status: 200, body: body_results_for_searchable_postcode_and_address_and_postcode_not_found, headers: {})
    end

    let(:claim) do
      claim = start_early_career_payments_claim
      claim.eligibility.update!(attributes_for(:early_career_payments_eligibility, :eligible))
      claim.address_line_1 = nil
      claim.address_line_2 = nil
      claim.address_line_3 = nil
      claim.postcode = nil
      claim.save
      claim
    end

    scenario "when no results returned from the API display error message" do
      expect(claim.valid?(:submit)).to eq false
      visit claim_path(claim.policy.routing_name, "postcode-search")

      # - What is your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_link(href: claim_path(EarlyCareerPayments.routing_name, "address"))

      fill_in "Postcode", with: "SE13 7UN"
      fill_in "House number or name (optional)", with: "40"
      click_on "Search"

      # - Select your home address
      expect(page).to have_text(I18n.t("questions.address.home.title"))
      expect(page).to have_text("There is a problem")
      expect(page).to have_text("Postcode not found")

      expect(claim.reload.address_line_1).not_to eql "38A"
      expect(claim.address_line_2).not_to eql "Wearside Road"
      expect(claim.address_line_3).not_to eql "London"
      expect(claim.postcode).not_to eql "SE13 7UN"
    end
  end
end
