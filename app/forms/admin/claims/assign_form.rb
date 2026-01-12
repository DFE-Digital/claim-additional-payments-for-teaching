module Admin::Claims
  class AssignForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :current_admin, :claim

    attribute :assign, :string
    attribute :colleague_id, :string

    validates :assign,
      inclusion: {
        in: %w[unassign myself colleague],
        message: "Select who to assign claim to"
      }

    validate :validate_colleague_selected

    def colleagues
      DfeSignIn::User.service_operators - [current_admin, claim.assigned_to].compact
    end

    def save
      case assign
      when "unassign"
        claim.update assigned_to: nil
      when "myself"
        claim.update assigned_to: current_admin
      when "colleague"
        claim.update assigned_to: colleague
      end
    end

    def unassignable?
      claim.assigned_to.present?
    end

    def can_assign_to_myself?
      claim.assigned_to != current_admin
    end

    private

    def colleague
      @colleague ||= DfeSignIn::User
        .service_operators
        .find_by(id: colleague_id)
    end

    def validate_colleague_selected
      return unless assign == "colleague"

      if colleague.nil?
        errors.add(:colleague_id, "Select a colleague")
      end
    end
  end
end
