module EarlyCareerPayments
  class SchoolCheckEmailDataExportPresenter
    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def subject
      ""
    end
  end
end
