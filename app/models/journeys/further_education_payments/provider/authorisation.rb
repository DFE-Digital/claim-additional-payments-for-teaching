module Journeys
  module FurtherEducationPayments
    module Provider
      class Authorisation
        def initialize(answers:, slug:)
          @answers = answers
          @slug = slug
        end

        def failure_reason
          return :organisation_mismatch if organisation_mismatch?

          nil
        end

        private

        attr_reader :answers, :slug

        def organisation_mismatch?
          answers.claim.school.ukprn != answers.dfe_sign_in_organisation_ukprn
        end
      end
    end
  end
end
