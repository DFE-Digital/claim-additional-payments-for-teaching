module Fwy
  class TeacherResource < Resource
    def find(trn, **params)
      response = get_request(
        "teachers/#{trn}", params: params
      )&.body
      return unless response

      Teacher.new(response)
    end
  end
end
