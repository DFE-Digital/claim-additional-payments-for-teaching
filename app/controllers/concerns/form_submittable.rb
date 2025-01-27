module FormSubmittable
  extend ActiveSupport::Concern

  #
  # This concern provides a way of handling form submissions for a generic slug sequence.
  #
  # The `new`, `show`, `create`, and `update` actions can be overridden only if necessary,
  # but it's discouraged as you could easily break the rendering cycle and callback chain.
  # If you need to override actions, you are probably not dealing with a form-based page sequence.
  #
  # The average use case will most likely only require to override slug-specific callbacks
  # that are used to execute custom logic before, after, or around certain actions.
  # In some cases, you may not need to define any callbacks at all.
  #
  # Default behaviour summary for each action:
  #
  #   controller#new: `redirect_to_first_slug`
  #   controller#show: `before_show` -> `render_template_for_current_slug`
  #   controller#update: `before_update` -> `handle_form_submission` ->
  #     -> `form#save` succeded? ->
  #       -> `execute_callback_if_exists(:after_form_save_success)` OR `redirect_to_next_slug`
  #     -> `form#save failed?` ->
  #       -> `execute_callback_if_exists(:after_form_save_failure)` OR `render_template_for_current_slug
  #   controller#create: same as controller#update
  #
  # When including this concern make sure that these methods are accessible in the controller:
  #
  # - `slugs`, `current_slug`, `next_slug` (normally from `PageSequence`, or overridden)
  # - `journey` (from `PartOfJourneyConcern`)
  # - `current_data_object`, required to load the form object
  # - any slug-specific callbacks (via a separate mixin)
  #
  # Important: `current_slug` is used to generate callbacks and assumed safe to use, i.e. derived
  # from constrained, validated or sanitised user input.
  #
  # Important: If there are other callbacks in the controller, you should be including this concern
  # **after** all the callbacks are defined. Placing this at the top is most likely a bad idea.
  # In most cases, form submission callbacks are meant to kick in last.
  #
  # See the implementation of `_set_slug_specific_callbacks` below for more details.

  included do
    before_action :_set_slug_specific_callbacks, only: [:show, :update, :create]
    before_action :before_show, only: :show
    before_action :before_update, only: [:update, :create]
    before_action :load_form_if_exists, only: [:show, :update, :create]
    around_action :handle_form_submission, only: [:update, :create]

    def new
      redirect_to_first_slug
    end

    def show
      render_template_for_current_slug
    end

    def create
      # Note: if implemented, this action will be yielded at the end of `handle_form_submission`
    end

    def update
      # Note: if implemented, this action will be yielded at the end of `handle_form_submission`
    end

    private

    #
    # Slug-specific callbacks are generated and executed around `show`, `update`, `create` actions,
    # For example, for the "personal-details" slug, the following callbacks are available:
    #
    # `personal_details_before_show`
    # `personal_details_before_update`
    # `personal_details_after_form_save_success` (*)
    # `personal_details_after_form_save_failure` (*)
    #
    # Ensure that the callbacks are implemented only where really needed.
    # Consider organizing the callback methods in one mixin per journey and controller.
    #
    # (*) If you need to define these callbacks, the default rendering behaviour will not be
    # followed, so you'll have to explicitly define what to do next (render/redirect_to).

    def _set_slug_specific_callbacks
      %i[before_show before_update after_form_save_success after_form_save_failure].each do |callback_name|
        self.class.send(:define_method, callback_name) do
          execute_callback_if_exists(callback_name)
        end
      end
    end

    def redirect_to_slug(slug)
      raise NoMethodError, "End of sequence: you must define #{current_slug.underscore}_after_form_save_success" unless next_slug
      raise NoMethodError, "Missing path helper for resource: \"#{path_helper_resource}\"; try overriding it with #path_helper_resource" unless respond_to?(:"#{path_helper_resource}_path")

      redirect_to send(:"#{path_helper_resource}_path", current_journey_routing_name, slug, request.query_parameters)
    end

    def redirect_to_next_slug
      redirect_to_slug(next_slug)
    end

    def redirect_to_first_slug
      redirect_to_slug(first_slug)
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

    def slugs
      journey.slug_sequence::SLUGS
    end

    def first_slug
      slugs.first.to_sym
    end

    def execute_callback_if_exists(callback_name)
      return false unless current_slug

      callback_name = :"#{current_slug.underscore}_#{callback_name}"
      if respond_to?(callback_name)
        log_event(callback_name) { send(callback_name) }
        return true
      end
      false
    end

    def handle_form_submission
      log_event(__method__)

      if @form.present?
        if journey.use_navigator?
          navigator.clear_furthest_ineligible_answer
        end

        if @form.save
          return if execute_callback_if_exists(:after_form_save_success)
          redirect_to_next_slug
        else
          return if execute_callback_if_exists(:after_form_save_failure)
          render_template_for_current_slug
        end
      else
        no_form_fallback
      end

      yield
    end

    def no_form_fallback
      if action_name == "create"
        redirect_to_first_slug
      elsif action_name == "update"
        redirect_to_next_slug
      end
    end

    def log_event(callback_name)
      logger.info "Executing callback ##{callback_name}"
      yield if block_given?
    end

    def load_form_if_exists
      @form ||= journey.form(journey_session:, params:, session:)
    end
  end
end
