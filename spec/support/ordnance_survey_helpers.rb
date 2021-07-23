module OrdnanceSurveyHelpers
  def stub_search_places_index(claim:)
    args = {
      query: WebMock::API.hash_including(
        {
          postcode: "SO169FX",
          key: "api-key-value",
          maxresults: 1
        }
      ),
      # truncated resultset (actual is 50, supplied 3) since not using any capture and replay tools eg VCR
      body: {
        results: [
          {
            DPA: {
              UPRN: "100062039919",
              UDPRN: "22785699",
              ADDRESS: "FLAT 1, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
              SUB_BUILDING_NAME: "FLAT 1",
              BUILDING_NAME: "MILLBROOK TOWER",
              THOROUGHFARE_NAME: "WINDERMERE AVENUE",
              POST_TOWN: "SOUTHAMPTON",
              POSTCODE: "SO16 9FX",
              RPC: "2",
              X_COORDINATE: 438092.0,
              Y_COORDINATE: 114637.0,
              STATUS: "APPROVED",
              LOGICAL_STATUS_CODE: "1",
              CLASSIFICATION_CODE: "RD06",
              CLASSIFICATION_CODE_DESCRIPTION: "Self Contained Flat (Includes Maisonette / Apartment)",
              LOCAL_CUSTODIAN_CODE: 1780,
              LOCAL_CUSTODIAN_CODE_DESCRIPTION: "SOUTHAMPTON",
              POSTAL_ADDRESS_CODE: "D",
              POSTAL_ADDRESS_CODE_DESCRIPTION: "A record which is linked to PAF",
              BLPU_STATE_CODE: "2",
              BLPU_STATE_CODE_DESCRIPTION: "In use",
              TOPOGRAPHY_LAYER_TOID: "osgb1000016364569",
              PARENT_UPRN: "100062691379",
              LAST_UPDATE_DATE: "12/11/2018",
              ENTRY_DATE: "03/05/2001",
              BLPU_STATE_DATE: "11/12/2007",
              LANGUAGE: "EN",
              MATCH: 1.0,
              MATCH_DESCRIPTION: "EXACT"
            }
          },
          {
            DPA: {
              UPRN: "100062039928",
              UDPRN: "22785700",
              ADDRESS: "FLAT 10, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
              SUB_BUILDING_NAME: "FLAT 10",
              BUILDING_NAME: "MILLBROOK TOWER",
              THOROUGHFARE_NAME: "WINDERMERE AVENUE",
              POST_TOWN: "SOUTHAMPTON",
              POSTCODE: "SO16 9FX",
              RPC: "2",
              X_COORDINATE: 438092.0,
              Y_COORDINATE: 114637.0,
              STATUS: "APPROVED",
              LOGICAL_STATUS_CODE: "1",
              CLASSIFICATION_CODE: "RD06",
              CLASSIFICATION_CODE_DESCRIPTION: "Self Contained Flat (Includes Maisonette / Apartment)",
              LOCAL_CUSTODIAN_CODE: 1780,
              LOCAL_CUSTODIAN_CODE_DESCRIPTION: "SOUTHAMPTON",
              POSTAL_ADDRESS_CODE: "D",
              POSTAL_ADDRESS_CODE_DESCRIPTION: "A record which is linked to PAF",
              BLPU_STATE_CODE: "2",
              BLPU_STATE_CODE_DESCRIPTION: "In use",
              TOPOGRAPHY_LAYER_TOID: "osgb1000016364569",
              PARENT_UPRN: "100062691379",
              LAST_UPDATE_DATE: "12/11/2018",
              ENTRY_DATE: "03/05/2001",
              BLPU_STATE_DATE: "11/12/2007",
              LANGUAGE: "EN",
              MATCH: 1.0,
              MATCH_DESCRIPTION: "EXACT"
            }
          },
          {
            DPA: {
              UPRN: "100062039929",
              UDPRN: "22785701",
              ADDRESS: "FLAT 11, MILLBROOK TOWER, WINDERMERE AVENUE, SOUTHAMPTON, SO16 9FX",
              SUB_BUILDING_NAME: "FLAT 11",
              BUILDING_NAME: "MILLBROOK TOWER",
              THOROUGHFARE_NAME: "WINDERMERE AVENUE",
              POST_TOWN: "SOUTHAMPTON",
              POSTCODE: "SO16 9FX",
              RPC: "2",
              X_COORDINATE: 438092.0,
              Y_COORDINATE: 114637.0,
              STATUS: "APPROVED",
              LOGICAL_STATUS_CODE: "1",
              CLASSIFICATION_CODE: "RD06",
              CLASSIFICATION_CODE_DESCRIPTION: "Self Contained Flat (Includes Maisonette / Apartment)",
              LOCAL_CUSTODIAN_CODE: 1780,
              LOCAL_CUSTODIAN_CODE_DESCRIPTION: "SOUTHAMPTON",
              POSTAL_ADDRESS_CODE: "D",
              POSTAL_ADDRESS_CODE_DESCRIPTION: "A record which is linked to PAF",
              BLPU_STATE_CODE: "2",
              BLPU_STATE_CODE_DESCRIPTION: "In use",
              TOPOGRAPHY_LAYER_TOID: "osgb1000016364569",
              PARENT_UPRN: "100062691379",
              LAST_UPDATE_DATE: "12/11/2018",
              ENTRY_DATE: "03/05/2001",
              BLPU_STATE_DATE: "11/12/2007",
              LANGUAGE: "EN",
              MATCH: 1.0,
              MATCH_DESCRIPTION: "EXACT"
            }
          }
        ]
      },
      status: 200
    }

    stub_request(:get, "https://api.os.uk/search/places/v1/postcode?key=api-key-value&postcode=SO169FX")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "Expect" => "",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus"
        }
      )
      .to_return(
        status: 200,
        body: args[:body].to_json,
        headers: {}
      )
  end

  def stub_search_places_show(claim:)
    args = {
      query: WebMock::API.hash_including(
        {
          query: "19, BD73BE",
          key: "api-key-value",
          maxresults: 1
        }
      ),
      body: {
        results: [
          {
            DPA: {
              UPRN: "100051230006",
              UDPRN: "1593790",
              ADDRESS: "19, TURNER PLACE, BRADFORD, BD7 3BE",
              BUILDING_NUMBER: "19",
              THOROUGHFARE_NAME: "TURNER PLACE",
              POST_TOWN: "BRADFORD",
              POSTCODE: "BD7 3BE",
              RPC: "1",
              X_COORDINATE: 414965.0,
              Y_COORDINATE: 432199.0,
              STATUS: "HISTORICAL",
              LOGICAL_STATUS_CODE: "8",
              CLASSIFICATION_CODE: "RD04",
              CLASSIFICATION_CODE_DESCRIPTION: "Terraced",
              LOCAL_CUSTODIAN_CODE: 4705,
              LOCAL_CUSTODIAN_CODE_DESCRIPTION: "BRADFORD MDC",
              POSTAL_ADDRESS_CODE: "D",
              POSTAL_ADDRESS_CODE_DESCRIPTION: "A record which is linked to PAF",
              BLPU_STATE_CODE: "4",
              BLPU_STATE_CODE_DESCRIPTION: "No longer existing",
              TOPOGRAPHY_LAYER_TOID: "osgb1000031905429",
              LAST_UPDATE_DATE: "11/05/2019",
              ENTRY_DATE: "05/04/2001",
              BLPU_STATE_DATE: "07/05/2019",
              LANGUAGE: "EN",
              MATCH: 0.4,
              MATCH_DESCRIPTION: "NO MATCH"
            }
          }
        ]
      },
      status: 200
    }

    stub_request(:get, "https://api.os.uk/search/places/v1/find?key=api-key-value&maxresults=1&query=19, BD73BE")
      .with(
        headers: {
          "Content-Type" => "application/json",
          "Expect" => "",
          "User-Agent" => "Typhoeus - https://github.com/typhoeus/typhoeus"
        }
      )
      .to_return(
        status: 200,
        body: args[:body].to_json,
        headers: {}
      )
  end
end
