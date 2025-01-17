module Journeys
  class Navigator
    attr_reader :current_slug, :slug_sequence, :params, :session

    def initialize(current_slug:, slug_sequence:, params:, session:)
      @current_slug = current_slug
      @slug_sequence = slug_sequence
      @params = params
      @session = session
    end

    def previous_slug
      last_valid_slug = nil

      slug_sequence.slugs.each do |slug|
        form_class = journey.form_class_for_slug(slug:)
        form = form_class.new(
          journey:,
          journey_session:,
          params:,
          session:
        )

        if current_slug == slug
          return last_valid_slug
        elsif form.respond_to?(:completed?)
          if form.completed?
            last_valid_slug = slug
          end
        elsif form.valid?
          last_valid_slug = slug
        else
          return last_valid_slug
        end
      end
    end

    def next_slug
      return "ineligible" if eligibility_checker.ineligible?

      forms = slug_sequence.slugs.map do |slug|
        form_class = journey.form_class_for_slug(slug:)

        raise "Form not found for journey: #{journey} slug: #{slug}" if form_class.nil?

        form = form_class.new(
          journey:,
          journey_session:,
          params:,
          session:
        )
        form
      end

      if current_slug.nil?
        forms.first
      else
        forms.each_with_index do |form, index|
          slug = journey.slug_for_form(form:)

          if form.respond_to?(:completed?)
            if !form.completed?
              return slug
            end
          elsif form.invalid?
            return slug
          end

          if current_slug == slug
            current_index = forms.index(form)
            next_index = current_index + 1
            next_form = forms[next_index]
            next_slug = journey.slug_for_form(form: next_form)

            return next_slug
          end
        end
      end
    end

    private

    def journey
      Journeys.for_routing_name(slug_sequence.journey_session.journey)
    end

    def journey_session
      slug_sequence.journey_session
    end

    def eligibility_checker
      @eligibility_checker ||= journey::EligibilityChecker.new(journey_session:)
    end
  end
end
