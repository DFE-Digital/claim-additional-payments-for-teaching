module Admin
  module Components
    class TestingPersonasController < BaseController
      def index
        @journeys = Journeys.all
          .select { |journey| helpers.journey_personas(journey).any? }
          .sort_by(&:full_name)
          .uniq { |journey| journey.full_name }
      end

      def show
        @journey = Journeys.all.find { |journey| journey.name.parameterize == params[:journey] }
        raise ActiveRecord::RecordNotFound if @journey.blank?

        @personas = helpers.journey_personas(@journey)
      end
    end
  end
end
