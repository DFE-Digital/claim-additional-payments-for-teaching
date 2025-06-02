module Admin
  module Claims
    module EmploymentHistory
      class DestroyEmploymentForm
        include ActiveModel::Model
        include ActiveModel::Attributes

        attr_reader :claim

        attribute :employment_id

        def initialize(claim, params: {})
          @claim = claim

          super(params)
        end

        def save!
          raise ActiveRecord::RecordInvalid unless employment_to_remove

          claim.eligibility.employment_history =
            claim.eligibility.employment_history.reject do |employment|
              employment == employment_to_remove
            end

          claim.save!
        end

        private

        def employment_to_remove
          @employment_to_remove ||= @claim
            .eligibility.employment_history.find { |e| e.id == employment_id }
        end
      end
    end
  end
end
