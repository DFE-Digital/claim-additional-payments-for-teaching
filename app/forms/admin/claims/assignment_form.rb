module Admin::Claims
  class AssignmentForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :flash_message
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
      return false if invalid?

      case assign
      when "unassign"
        ApplicationRecord.transaction do
          claim.notes.create!(
            body: "This claim was unassigned from #{claim.assigned_to.full_name}",
            created_by: current_admin
          )

          @flash_message = "This claim has now been successfully unassigned from #{claim.assigned_to.full_name}"

          claim.update! assigned_to: nil
        end
      when "myself"
        ApplicationRecord.transaction do
          claim.notes.create!(
            body: "This claim was assigned to #{current_admin.full_name}",
            created_by: current_admin
          )

          @flash_message = "This claim has now been successfully assigned to #{current_admin.full_name}"

          claim.update! assigned_to: current_admin
        end
      when "colleague"
        ApplicationRecord.transaction do
          claim.notes.create!(
            body: "This claim was assigned to #{colleague.full_name}",
            created_by: current_admin
          )

          @flash_message = "This claim has now been successfully assigned to #{colleague.full_name}"

          claim.update! assigned_to: colleague
        end
      end
    rescue
      @flash_message = nil

      false
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
