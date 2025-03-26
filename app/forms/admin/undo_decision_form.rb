module Admin
  class UndoDecisionForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :claim, :decision, :current_admin

    attribute :notes, :string

    validates :notes,
      presence: {
        message: "Enter a message to explain why you are making this amendment"
      }

    validate :validate_decision_undoable
    validate :validate_processable

    def initialize(claim:, decision:, current_admin:, params: {})
      @claim = claim
      @decision = decision
      @current_admin = current_admin

      super(params)
    end

    def save
      return false if invalid?

      amendment = Amendment.undo_decision(decision, amendment_params.merge(created_by: current_admin))
      amendment.persisted?
    end

    def processable?
      return false if claim.high_risk_ol_idv? && !current_admin.is_service_admin?

      true
    end

    private

    def validate_processable
      errors.add(:base, "This claim can only have its decision undone by an SRO") if !processable?
    end

    def validate_decision_undoable
      errors.add(:base, "This claim cannot have its decision undone") unless claim.decision_undoable?
    end

    def amendment_params
      {
        notes:
      }
    end
  end
end
