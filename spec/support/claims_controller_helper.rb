module ClaimsControllerHelper
  def mock_claims_controller_address_data
    allow_any_instance_of(OrdnanceSurvey::Client)
      .to receive_message_chain(:api, :search_places, :index)
      .and_return(mocked_address_data)
  end

  def mocked_address_data
    [
      {
        address: "Flat 1, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
        address_line_1: "FLAT 1, MILLBROOK TOWER",
        address_line_2: "WINDERMERE AVENUE",
        address_line_3: "SOUTHAMPTON",
        postcode: "SO16 9FX"
      },
      {
        address: "Flat 10, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
        address_line_1: "FLAT 10, MILLBROOK TOWER",
        address_line_2: "WINDERMERE AVENUE",
        address_line_3: "SOUTHAMPTON",
        postcode: "SO16 9FX"
      },
      {
        address: "Flat 11, Millbrook Tower, Windermere Avenue, Southampton, SO16 9FX",
        address_line_1: "FLAT 11, MILLBROOK TOWER",
        address_line_2: "WINDERMERE AVENUE",
        address_line_3: "SOUTHAMPTON",
        postcode: "SO16 9FX"
      }
    ]
  end
end
