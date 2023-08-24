# spec/helpers/dqt_stub_helper.rb
module DqtApiHelper
  def stub_dqt_request(teacher_reference_number, date_of_birth)
    body = <<~JSON
      {
        "trn": "#{teacher_reference_number}",
        "ni_number": "YW247620A",
        "qualified_teacher_status": {
            "name": "Qualified teacher (trained)",
            "state": "Active",
            "state_name": "Active",
            "qts_date": "2022-06-20T00:00:00Z"
        },
        "induction": null,
        "initial_teacher_training": {
            "state": "Active",
            "state_code": "Active",
            "programme_start_date": "2021-10-20T00:00:00Z",
            "programme_end_date": null,
            "programme_type": null,
            "result": "Pass",
            "subject1": "Maths and Info. Technology",
            "subject2": null,
            "subject3": null,
            "qualification": "Postgraduate Certificate in Education",
            "subject1_code": "G9006",
            "subject2_code": null,
            "subject3_code": null
        },
        "qualifications": [],
        "name": "Elsie Hynd",
        "dob": "#{date_of_birth}T00:00:00",
        "active_alert": false,
        "state": "Active",
        "state_name": "Active"
      }
    JSON

    stub_request(:get, "#{ENV["DQT_BASE_URL"]}/v1/teachers/#{teacher_reference_number}?birthdate=#{date_of_birth}")
      .with(
        headers: {
          "Accept" => "*/*",
          "Authorization" => "Bearer #{ENV["DQT_API_KEY"]}",
          "Host" => URI.parse(ENV["DQT_BASE_URL"]).host
        }
      )
      .to_return(status: 200, body: body, headers: {})
  end
end
