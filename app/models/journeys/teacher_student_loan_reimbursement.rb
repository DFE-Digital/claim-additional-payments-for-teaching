# frozen_string_literal: true

module Journeys
  module TeacherStudentLoanReimbursement
    extend Base
    extend self

    ROUTING_NAME = "student-loans"
    VIEW_PATH = "student_loans"
    I18N_NAMESPACE = "student_loans"
    POLICIES = [Policies::StudentLoans]

    def forms
      array = []

      array << if TeacherAuth::Config.instance.bypass?
        Debug::TeacherAuth::SignInForm
      else
        SignInForm
      end

      array + [
        ClaimSchoolForm,
        ClaimSchoolResultsForm,
        QualificationsCheckForm,
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
    end

    def requires_student_loan_details?
      true
    end
  end
end
