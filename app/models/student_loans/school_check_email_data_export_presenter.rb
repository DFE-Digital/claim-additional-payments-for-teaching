module StudentLoans
  class SchoolCheckEmailDataExportPresenter
    include StudentLoans::PresenterMethods

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def subject
      subject_list(claim.eligibility.subjects_taught).downcase
    end
  end
end
