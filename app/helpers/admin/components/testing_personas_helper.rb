module Admin
  module Components
    module TestingPersonasHelper
      def personas
        @personas ||= ::TestingPersonaRegistry.testing_personas
          .reject { |persona| persona[:journey_name].blank? }
      end

      def journey_personas(journey)
        personas
          .select { |persona| persona[:journey_name] == journey.full_name }
          .sort_by { |persona| [(persona[:outcome] == "success") ? 0 : 1, persona[:title]] }
      end
    end
  end
end
