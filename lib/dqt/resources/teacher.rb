module Dqt
  class TeacherResource < Resource
    def find(trn, **)
      response_body = find_raw(trn, **)
      return unless response_body

      Teacher.new(response_body)
    end

    def find_raw(trn, **params)
      response = get_request(
        "persons/#{trn}", params: params
      )

      if response && response.status == 200
        response.body
      end
    end
  end
end
