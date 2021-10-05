module AutomatedChecks
  class ClaimVerifier
    def initialize(
      claim:,
      dqt_teacher_statuses:,
      admin_user: nil,
      verifiers: [
        ClaimVerifiers::Identity.new(
          admin_user: admin_user,
          claim: claim,
          dqt_teacher_statuses: dqt_teacher_statuses
        ),
        ClaimVerifiers::Qualifications.new(
          admin_user: admin_user,
          claim: claim,
          dqt_teacher_statuses: dqt_teacher_statuses
        )
      ]
    )
      self.admin_user = admin_user
      self.claim = claim
      self.qualified_teaching_statuses = dqt_teacher_statuses
      self.verifiers = verifiers
    end

    def perform
      verifiers.count do |verifier|
        verifier.perform.instance_of? Task
      end
    end

    private

    attr_accessor :admin_user, :claim, :qualified_teaching_statuses, :verifiers
  end
end
