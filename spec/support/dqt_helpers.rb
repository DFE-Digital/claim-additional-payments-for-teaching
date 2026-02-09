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
      lastName: "Decerqueira",
      firstName: "Kenneth",
      dateOfBirth: params[:birthdate],
      nationalInsuranceNumber: params[:nino],
      qts: {
        holdsFrom: "2022-01-09"
      },
      routesToProfessionalStatuses: [
        {
          holdsFrom: "2022-01-09",
          trainingSubjects: [
            {
              name: "mathematics",
              reference: "G100"
            }
          ],
          trainingStartDate: "2024-01-09",
          trainingEndDate: nil,
          routeToProfessionalStatusType: {
            name: "BA (Hons)"
          }
        }
      ],
      induction: {
        status: "Passed",
        startDate: "2024-01-09",
        completedDate: nil,
        exemptionReasons: []
      },
      alerts: []
    }, body)

    query_params = {
      include: "alerts,induction,routesToProfessionalStatuses"
    }

    stub_request(:get, "#{ENV["DQT_API_URL"]}persons/#{trn}")
      .with(query: WebMock::API.hash_including(query_params))
      .to_return(
        body: body.to_json,
        status: status,
        headers: {"Content-Type" => "application/json"}
      )
  end

  def stub_dqt_empty_response(trn: 1231234)
    query_params = {
      include: "alerts,induction,routesToProfessionalStatuses"
    }

    stub_request(:get, "#{ENV["DQT_API_URL"]}persons/#{trn}")
      .with(query: WebMock::API.hash_including(query_params))
      .to_return(
        body: {}.to_json,
        status: 404,
        headers: {"Content-Type" => "application/json"}
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
