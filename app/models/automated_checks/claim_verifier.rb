module AutomatedChecks
  class ClaimVerifier
    def initialize(claim:, dqt_teacher_status:, admin_user: nil, verifiers: nil)
      @admin_user = admin_user
      @claim = claim
      @dqt_teacher_status = dqt_teacher_status
      @verifiers = verifiers || build_verifiers
    end

    def perform
      verifiers.count do |verifier|
        verifier.perform.instance_of? Task
      end
    end

    private

    attr_accessor :admin_user, :claim, :dqt_teacher_status, :verifiers

    def build_verifiers
      claim.policy.verifiers_for_claim(claim).map do |verifier|
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
