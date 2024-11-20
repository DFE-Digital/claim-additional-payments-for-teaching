# frozen_string_literal: true

# Used to model the sequence of pages that make up the claim process.
module Journeys
  class PageSequence
    attr_reader :current_slug

    DEAD_END_SLUGS = %w[complete existing-session eligible-later future-eligibility ineligible check-your-email expired-link unauthorised]
    OPTIONAL_SLUGS = %w[postcode-search select-home-address reset-claim]

    def initialize(slug_sequence, completed_slugs, current_slug, journey_session)
      @current_slug = current_slug
      @slug_sequence = slug_sequence
      @completed_slugs = completed_slugs
      @journey_session = journey_session
    end

    def slugs
      @slug_sequence.slugs
    end

    def next_slug
      return "ineligible" if journey_ineligible?

      if claim_submittable?
        return "student-loan-amount" if updating_personal_details? && in_sequence?("student-loan-amount")
        return "check-your-answers"
      end

      return slugs[current_slug_index + 2] if can_skip_next_slug?

      slugs[current_slug_index + 1]
    end

    def previous_slug
      return nil if current_slug_index.zero? || current_slug.in?(DEAD_END_SLUGS)
      slugs[current_slug_index - 1]
    end

    def in_sequence?(slug)
      slugs.include?(slug)
    end

    def has_completed_journey_until?(slug)
      return true if DEAD_END_SLUGS.include?(slug)
      incomplete_slugs.empty?
    end

    def completed_slugs
      # /address is considered completed if provided via /postcode-search and /select-home-address
      return @completed_slugs + ["address"] if answers.postcode.present?

      @completed_slugs
    end

    def next_required_slug
      (slugs - completed_slugs - OPTIONAL_SLUGS).first
    end

    def requires_authorisation?(slug)
      @slug_sequence.try(:requires_authorisation?, slug) || false
    end

    def unauthorised_path(slug, failure_reason)
      @slug_sequence.unauthorised_path(slug, failure_reason)
    end

    private

    delegate :answers, to: :@journey_session

    def updating_personal_details?
      current_slug == "personal-details"
    end

    def incomplete_slugs
      (slugs.slice(0, current_slug_index) - OPTIONAL_SLUGS - completed_slugs)
    end

    def can_skip_next_slug?
      # This allows 'address' page to be skipped when the postcode is present
      # Occurs when populated from 'postcode-search' and the subsequent 'select-home-address' screens
      true if current_slug == "select-home-address" && answers.postcode.present?
    end

    def current_slug_index
      slugs.index(current_slug) || 0
    end

    def journey
      @journey_session.class.module_parent
    end

    def claim_submittable?
      journey::ClaimSubmissionForm.new(journey_session: @journey_session).valid?
    end

    def journey_ineligible?
      @journey_ineligible ||= journey::EligibilityChecker.new(journey_session: @journey_session).ineligible?
    end
  end
end
