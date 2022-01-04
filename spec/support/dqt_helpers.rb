module DqtHelpers
  def stub_qualified_teaching_statuses_show(
    trn: 1231234,
    body: {},
    params: {},
    status: 200
  )

    params = {
      birthdate: "1966-06-06",
      nino: "AB123123A"
    }.merge(params)

    body = merge_recursively({
      trn: trn,
      ni_number: params[:nino],
      name: "Rick Sanchez",
      dob: "66-06-06T00:00:00",
      active_alert: false,
      state: 0,
      state_name: "Active",
      qualified_teacher_status: {
        name: "Qualified teacher (trained)",
        qts_date: "1666-06-06T00:00:00",
        state: 0,
        state_name: "Active"
      },
      induction: {
        start_date: "2021-07-01T00:00:00Z",
        completion_date: "2021-07-05T00:00:00Z",
        status: "Pass",
        state: 0,
        state_name: "Active"
      },
      initial_teacher_training: {
        programme_start_date: "666-06-06T00:00:00",
        programme_end_date: "2021-07-04T00:00:00Z",
        programme_type: "Overseas Trained Teacher Programme",
        result: "Pass",
        subject1: "G100",
        subject2: nil,
        subject3: nil,
        qualification: "BA (Hons)",
        state: 0,
        state_name: "Active"
      }
    }, body)

    stub_request(:post, (ENV["DQT_BEARER_BASE_URL"]).to_s)
      .with(body: Faraday::FlatParamsEncoder.encode(bearer_params))
      .to_return(
        body: {access_token: "1234"}.to_json,
        status: 200
      )

    stub_request(:get, "#{ENV["DQT_BASE_URL"]}teachers/#{trn}")
      .with(query: WebMock::API.hash_including(params))
      .to_return(
        body: body.to_json,
        status: status,
        headers: {"Content-Type" => "application/json"}
      )
  end

  private

  def bearer_params
    {
      grant_type: ENV["DQT_BEARER_GRANT_TYPE"],
      scope: ENV["DQT_BEARER_SCOPE"],
      client_id: ENV["DQT_BEARER_CLIENT_ID"],
      client_secret: ENV["DQT_BEARER_CLIENT_SECRET"]
    }
  end

  def merge_recursively(a, b)
    a.merge!(b) do |key, a_item, b_item|
      if a_item.is_a?(Hash)
        merge_recursively(a_item, b_item)
      else
        b_item
      end
    end
  end
end
