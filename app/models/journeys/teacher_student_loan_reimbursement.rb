# frozen_string_literal: true

module Journeys
  module TeacherStudentLoanReimbursement
    extend Base
    extend self

    ROUTING_NAME = "student-loans"
    VIEW_PATH = "student_loans"
    I18N_NAMESPACE = "student_loans"
    POLICIES = [Policies::StudentLoans]

    FORMS = [
      ClaimSchoolForm,
      ClaimSchoolResultsForm,
      QualificationDetailsForm,
      QtsYearForm,
      SubjectsTaughtForm,
      StillTeachingForm,
      StillTeachingTpsForm,
      LeadershipPositionForm,
      MostlyPerformedLeadershipDutiesForm,
      ResetClaimForm,
      SelectClaimSchoolForm,
      SelectHomeAddressForm,
      EligibilityConfirmedForm,
      StudentLoanAmountForm,
      CheckYourAnswersForm,
      ConfirmationForm,
      IneligibleForm
    ].freeze

    def requires_student_loan_details?
      true
    end
  end
end
