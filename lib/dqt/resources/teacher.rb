module Dqt
  class TeacherResource < Resource
    def find(trn, **params)
      response = find_raw(trn, **params)

      Teacher.new(response)
    end

    def find_raw(trn, **params)
      response = get_request(
        "teachers/#{trn}", params: params
      )&.body
      return unless response

      response
    end
  end
end
