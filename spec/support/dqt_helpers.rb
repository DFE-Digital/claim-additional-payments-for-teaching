module DqtHelpers
  def stub_qualified_teaching_status_show(claim:, overrides: nil)
    defaults = {
      query: WebMock::API.hash_including(
        {
          trn: claim.teacher_reference_number,
          niNumber: claim.national_insurance_number
        }
      ),
      body: {
        data: [
          {
            trn: claim.teacher_reference_number,
            name: "#{claim.first_name} #{claim.surname}",
            doB: claim.date_of_birth,
            niNumber: claim.national_insurance_number,
            qtsAwardDate: "2021-03-23T10:54:57.199Z",
            ittSubject1Code: "string",
            ittSubject2Code: "string",
            ittSubject3Code: "string",
            activeAlert: true
          }
        ],
        "message": nil
      },
      status: 200
    }

    args = overrides ? merge_recursively(defaults, overrides) : defaults

    stub_request(:get, "#{ENV["DQT_CLIENT_HOST"]}:#{ENV["DQT_CLIENT_PORT"]}/api/qualified-teachers/qualified-teaching-status")
      .with(query: args[:query])
      .to_return(
        body: args[:body].to_json,
        status: args[:status]
      )
  end

  private

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
