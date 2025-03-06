module Journeys
  module AdditionalPaymentsForTeaching
    class CorrectSchoolForm < Form
      attribute :change_school, :boolean
      attribute :current_school_id, :string

      delegate :address, :name, to: :current_school, prefix: true, allow_nil: true
      delegate :school_somewhere_else?, to: :answers

      def save
        journey_session.answers.assign_attributes(eligibility_attributes)
        journey_session.save!
      end

      def current_school_id
        @current_school_id ||= permitted_params.fetch(:current_school_id, current_school&.id)
      end

      private

      def current_school
        @current_school ||= answers.recent_tps_school || answers.current_school
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
