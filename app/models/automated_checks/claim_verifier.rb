module AutomatedChecks
  class ClaimVerifier
    def initialize(
      claim:,
      dqt_teacher_status:,
      admin_user: nil,
      verifiers: [
        ClaimVerifiers::Identity.new(
          admin_user: admin_user,
          claim: claim,
          dqt_teacher_status: dqt_teacher_status
        ),
        ClaimVerifiers::Qualifications.new(
          admin_user: admin_user,
          claim: claim,
          dqt_teacher_status: dqt_teacher_status
        )
      ]
    )
      self.admin_user = admin_user
      self.claim = claim
      self.qualified_teaching_status = dqt_teacher_status
      self.verifiers = verifiers
    end

    def perform
      verifiers.count do |verifier|
        verifier.perform.instance_of? Task
      end
    end

    private

    attr_accessor :admin_user, :claim, :qualified_teaching_status, :verifiers
  end
end
