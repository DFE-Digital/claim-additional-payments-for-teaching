module Fwy
  class TeacherResource < Resource
    def find(trn, **params)
      Teacher.new(
        get_request(
          "teachers/#{trn}", params: params
        ).body
      )
    end
  end
end
