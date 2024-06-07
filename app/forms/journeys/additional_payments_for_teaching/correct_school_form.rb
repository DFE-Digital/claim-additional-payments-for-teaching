module Journeys
  module AdditionalPaymentsForTeaching
    class CorrectSchoolForm < Form
      attribute :change_school, :boolean
      attribute :current_school_id, :string

      delegate :address, :name, to: :current_school, prefix: true, allow_nil: true
      delegate :eligibility, to: :claim
      delegate :school_somewhere_else?, to: :eligibility

      def save
        claim.update(eligibility_attributes:)
        journey_session.answers.assign_attributes(eligibility_attributes)
        journey_session.save
        claim.reset_eligibility_dependent_answers(["current_school_id"])
        true
      end

      def current_school_id
        @current_school_id ||= permitted_params.fetch(:current_school_id, current_school&.id)
      end

      private

      def current_school
        @current_school ||= journey_session.recent_tps_school || claim.school
      end

      def change_school?
        change_school || current_school_id.nil? || current_school_id == "somewhere_else"
      end

      def eligibility_attributes
        return {current_school_id: nil, school_somewhere_else: true} if change_school?

        {current_school_id:, school_somewhere_else: false}
      end
    end
  end
end
