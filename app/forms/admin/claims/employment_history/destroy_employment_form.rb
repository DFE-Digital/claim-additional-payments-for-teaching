module Admin
  module Claims
    module EmploymentHistory
      class DestroyEmploymentForm
        include ActiveModel::Model
        include ActiveModel::Attributes

        attr_reader :claim

        attr_accessor :deleted_by

        attribute :employment_id

        validates :deleted_by, presence: true

        def initialize(claim, params: {})
          @claim = claim

          super(params)
        end

        def save!
          eligibility = claim.eligibility

          employment = eligibility.employment_history.find { |e| e.id == employment_id }

          raise ActiveRecord::RecordInvalid unless employment

          employment.deleted_by = deleted_by
          employment.deleted_at = DateTime.now

          eligibility.employment_history_will_change!

          eligibility.save!
        end
      end
    end
  end
end
