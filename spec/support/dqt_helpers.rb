module DqtHelpers
  def stub_qualified_teaching_statuses_show(
    body: {},
    query: {},
    status: 200
  )

    query = {
      trn: 1231234,
      ni: "AB123123A"
    }.merge(query)

    body = merge_recursively({
      data: [
        {
          trn: query[:trn],
          name: "Rick Sanchez",
          doB: "66-06-06T00:00:00",
          niNumber: query[:niNumber],
          qtsAwardDate: "1666-06-06T00:00:00",
          ittSubject1Code: "G100",
          ittSubject2Code: nil,
          ittSubject3Code: nil,
          activeAlert: true,
          qualificationName: nil,
          ittStartDate: "666-06-06T00:00:00"
        }
      ],
      message: nil
    }, body)

    stub_request(:get, "#{ENV["DQT_CLIENT_HOST"]}:#{ENV["DQT_CLIENT_PORT"]}/api/qualified-teachers/qualified-teaching-status")
      .with(query: WebMock::API.hash_including(query))
      .to_return(
        body: body.to_json,
        status: status
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
