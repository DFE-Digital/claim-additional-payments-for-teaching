module FormSubmittable
  extend ActiveSupport::Concern

  included do
    before_action :load_form_if_exists, only: [:show, :update, :create]

    def new
      redirect_to_next_slug
    end

    def show
      return redirect_to_next_slug if @form.redirect_to_next_slug?

      render_template_for_current_slug

      @form.after_render
    end

    def create
      handle_form_submission
    end

    def update
      handle_form_submission
    end

    private

    def query_parameters_to_include(slug)
      if include_query_parameters?(slug)
        request.query_parameters
      else
        {}
      end
    end

    # if we are changing answer and sent back to relevant check answers page
    # we remove any query params
    # otherwise navigator will continue
    def include_query_parameters?(slug)
      if navigator.changing_answer?
        params[:change] != slug
      else
        true
      end
    end

    def redirect_to_next_slug
      redirect_to claim_path(
        current_journey_routing_name,
        navigator.next_slug,
        navigator.query_params.presence || query_parameters_to_include(navigator.next_slug)
      )
    end

    def render_template_for_current_slug
      render current_template
    end

    def current_template
      current_slug.underscore
    end

    def handle_form_submission
      if @form.present?
        if @form.save
          navigator.clear_impermissible_answers
          navigator.clear_furthest_ineligible_answer

          redirect_to_next_slug
        else
          render_template_for_current_slug
        end
      else
        no_form_fallback
      end
    end

    def no_form_fallback
      redirect_to_next_slug
    end

    def load_form_if_exists
      @form ||= journey.form(journey_session:, params:, session:)
    end

    def current_user
      DfeSignIn::NullUser.new
    end
    helper_method :current_user
  end
end
