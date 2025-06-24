module FormSubmittable
  extend ActiveSupport::Concern

  included do
    before_action :load_form_if_exists, only: [:show, :update, :create]

    def new
      redirect_to_next_slug
    end

    def show
      render_template_for_current_slug
    end

    def create
      handle_form_submission
    end

    def update
      handle_form_submission
    end

    private

    def redirect_to_slug(slug)
      raise NoMethodError, "End of sequence: you must define #{current_slug.underscore}_after_form_save_success" unless next_slug
      raise NoMethodError, "Missing path helper for resource: \"#{path_helper_resource}\"; try overriding it with #path_helper_resource" unless respond_to?(:"#{path_helper_resource}_path")

      redirect_to send(:"#{path_helper_resource}_path", current_journey_routing_name, slug, query_parameters_to_include(slug))
    end

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
      redirect_to_slug(next_slug)
    end

    def path_helper_resource
      controller_name.singularize
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
  end
end
