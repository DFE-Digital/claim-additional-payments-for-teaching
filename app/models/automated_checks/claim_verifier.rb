module AutomatedChecks
  class ClaimVerifier
    def initialize(claim:, dqt_teacher_status:, admin_user: nil, verifiers: nil)
      self.admin_user = admin_user
      self.claim = claim
      self.dqt_teacher_status = dqt_teacher_status
      self.verifiers = verifiers || build_verifiers
    end

    def perform
      verifiers.count do |verifier|
        verifier.perform.instance_of? Task
      end
    end

    private

    attr_accessor :admin_user, :claim, :dqt_teacher_status, :verifiers

    def build_verifiers
      return [] unless claim.policy.const_defined?(:VERIFIERS)

      claim.policy::VERIFIERS.map do |verifier|
        args = verifier.instance_method(:initialize).parameters.map do |params|
          key = params[-1]
          value = send(key)

          [key, value]
        end.to_h

        verifier.new(**args)
      end
    end
  end
end
