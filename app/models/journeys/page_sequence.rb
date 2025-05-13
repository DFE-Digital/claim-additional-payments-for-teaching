# frozen_string_literal: true

# Used to model the sequence of pages that make up the claim process.
module Journeys
  class PageSequence
    DEAD_END_SLUGS = %w[complete existing-session eligible-later future-eligibility ineligible check-your-email expired-link unauthorised]
  end
end
