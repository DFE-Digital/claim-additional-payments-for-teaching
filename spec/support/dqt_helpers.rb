module DqtHelpers
  def stub_qualified_teaching_status_show(claim:)
    stub_request(:get, "#{ENV["DQT_CLIENT_HOST"]}:#{ENV["DQT_CLIENT_PORT"]}/api/qualified-teachers/qualified-teaching-status").with(
      query: WebMock::API.hash_including(
        {
          trn: claim.teacher_reference_number,
          niNumber: claim.national_insurance_number
        }
      )
    ).to_return(
      body: <<~JSON
        {
          "data": [
            {
              "trn": "#{claim.teacher_reference_number}",
              "name": "#{claim.first_name} #{claim.surname}",
              "doB": "#{claim.date_of_birth}",
              "niNumber": "#{claim.national_insurance_number}",
              "qtsAwardDate": "2021-03-23T10:54:57.199Z",
              "ittSubject1Code": "string",
              "ittSubject2Code": "string",
              "ittSubject3Code": "string",
              "activeAlert": true
            }
          ],
          "message": null
        }
      JSON
    )
  end
end
