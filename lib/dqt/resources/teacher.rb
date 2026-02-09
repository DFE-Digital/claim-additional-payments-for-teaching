module Dqt
  class TeacherResource < Resource
    def find(trn, **)
      response = find_raw(trn, **)
      return unless response

      Teacher.new(response)
    end

    def find_raw(trn, **params)
      get_request(
        "persons/#{trn}", params: params
      )&.body
    end
  end
end
