module Journeys
  class Navigator
    attr_reader :current_slug, :slug_sequence, :params, :session

    def initialize(current_slug:, slug_sequence:, params:, session:)
      @current_slug = current_slug
      @slug_sequence = slug_sequence
      @params = params
      @session = session
    end

    # when showing a form
    # work out where the backlink should take the user
    def previous_slug
      last_valid_slug = nil

      slug_sequence.slugs.each do |slug|
        form_class = journey.form_class_for_slug(slug:)
        form = form_class.new(
          journey:,
          journey_session:,
          params: form_params(form_class),
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

    # given the current slug
    # returns the next slug in the sequence
    # used when a user hits continue on a form
    def next_slug
      return "ineligible" if eligibility_checker.ineligible?

      if current_slug.nil?
        journey.slug_for_form(form: forms.first)
      else
        forms.each_with_index do |form, index|
          slug = journey.slug_for_form(form:)

          if form.respond_to?(:completed?)
            if !form.completed?
              Rails.logger.info "navigator-debug: next_slug is #{slug} as not completed" if Rails.env.development?
              return slug
            end
          elsif form.invalid?
            Rails.logger.info "navigator-debug: next_slug is #{slug} as invalid" if Rails.env.development?

            return slug
          end

          # if we are changing answer
          # if possible to want to return to relevant check answer page
          # though may not be possible if new unanswered questions are revealed
          if changing_answer?
            return slug if form == forms.last
            return slug if params[:change] == slug

            next
          end

          # check if want to resume an existing session
          # if so carry on where we left off
          if form.resume?
            return furthest_permissible_slug
          end

          if current_slug == slug
            current_index = forms.index(form)
            next_index = current_index + 1
            next_form = forms[next_index]
            next_slug = journey.slug_for_form(form: next_form)

            Rails.logger.info "navigator-debug: next_slug is #{next_slug}" if Rails.env.development?

            return next_slug
          end
        end
      end
    end

    def requires_authorisation?
      journey::SlugSequence::RESTRICTED_SLUGS.include?(current_slug)
    end

    # is the user allowed to vist the current slug?
    # based on their permissions
    def authorised_slug?
      auth_checker.failure_reason.nil?
    end

    # is the user allowed to visit the current_slug?
    # use this to guard against a user jumping ahead in a journey
    def permissible_slug?
      # TODO: should only show confirmation is subbmitted id in session present
      return true if current_slug == "confirmation"

      if current_slug == "ineligible" && eligibility_checker.ineligible?
        return true
      end

      forms.each do |form|
        slug = journey.slug_for_form(form:)

        if current_slug == slug
          return true
        end

        if form.respond_to?(:completed?)
          if !form.completed?
            Rails.logger.info "navigator-debug: permissible_slug? is false for #{slug} as not completed" if Rails.env.development? || Rails.env.test?
            return false
          end
        elsif form.invalid?
          Rails.logger.info "navigator-debug: permissible_slug? is false for #{slug} as form invalid" if Rails.env.development? || Rails.env.test?
          return false
        end
      end
    end

    # ignoring the current_slug
    # return the last slug the user is allowed to visit
    # this is the furthest slug available in the journey given their state
    # use this when user requests a non permissible slug
    def furthest_permissible_slug
      last_slug = nil

      forms.each_with_index do |form, index|
        slug = journey.slug_for_form(form:)

        if form.respond_to?(:completed?)
          if form.completed?
            last_slug = slug
          else
            return slug
          end
        elsif form.valid?
          last_slug = slug
        else
          return slug
        end
      end

      last_slug
    end

    # when a user changes an answer
    # an existing answer might no longer be applicable
    # if so we clear all those inaccessbile answers
    def clear_impermissible_answers
      ApplicationRecord.transaction do
        impermissible_forms.each do |form|
          form.clear_answers_from_session
        end
      end
    end

    # should we clear the furthest most inelgible answer
    # we do so if we are changing answer of a previous page
    def clear_furthest_ineligible_answer
      return unless eligibility_checker.ineligible?

      furthest_form = permissible_forms.last

      return if furthest_form.nil?

      furthest_slug = journey.slug_for_form(form: furthest_form)

      if current_slug != furthest_slug
        furthest_form.clear_answers_from_session
      end
    end

    def query_params
      if eligibility_checker.ineligible?
        {ineligible_reason: eligibility_checker.ineligibility_reason}
      end
    end

    # returns truthy if changing answer
    # the value is set to the slug of returning check answers page
    # as a journey can have multiple check answer pages
    def changing_answer?
      params[:change].present?
    end

    private

    def impermissible_forms
      all_forms.reject do |form|
        permissible_forms.map { |f| f.class }.include?(form.class)
      end
    end

    def all_forms
      @all_forms ||= journey::SlugSequence::SLUGS.map do |slug|
        form_class = journey.form_class_for_slug(slug:)

        raise "Form not found for journey: #{journey} slug: #{slug}" if form_class.nil?

        form = form_class.new(
          journey:,
          journey_session:,
          params: form_params(form_class),
          session:
        )
        form
      end
    end

    def permissible_forms
      return @permissible_forms if @permissible_forms

      index = forms.find_index do |form|
        slug = journey.slug_for_form(form:)

        slug == furthest_permissible_slug
      end

      @permissible_forms ||= forms.take(index)
    end

    def forms
      @forms ||= slug_sequence.slugs.map do |slug|
        form_class = journey.form_class_for_slug(slug:)

        raise "Form not found for journey: #{journey} slug: #{slug}" if form_class.nil?

        form = form_class.new(
          journey:,
          journey_session:,
          params: form_params(form_class),
          session:
        )
        form
      end
    end

    def journey
      slug_sequence.journey
    end

    def journey_session
      slug_sequence.journey_session
    end

    def eligibility_checker
      @eligibility_checker ||= journey::EligibilityChecker.new(journey_session:)
    end

    def form_params(form_class)
      params.fetch(form_class.model_name.param_key, {}).slice(
        *form_class.attribute_names.map(&:to_sym)
      )
    end

    def auth_checker
      @auth_checker ||= journey::Authorisation.new(
        answers: journey_session.answers
      )
    end
  end
end
