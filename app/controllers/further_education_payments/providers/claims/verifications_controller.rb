module FurtherEducationPayments
  module Providers
    module Claims
      class VerificationsController < BaseController
        FORMS = [
          RoleAndExperienceForm,
          CheckAnswersForm,
        ]

        def edit
          @form = current_form

          render @form.template
        end

        def update
          @form = current_form

          if @form.update(verification_form_params)
            redirect_to(
              edit_further_education_payments_providers_claim_verification_path(
                claim
              )
            )
          else
            render @form.template, status: :unprocessable_entity
          end
        end

        private

        # TODO RL: Handle change links, fetch the form from a param
        def current_form
          @current_form ||= forms.detect(&:incomplete?)
        end

        def forms
          @forms ||= FORMS.map do |form_class|
            form_class.new(
              claim: claim,
              user: current_user,
              params: claim.eligibility.attributes.slice(
                *form_class.attribute_names.map(&:to_s)
              )
            )
          end
        end

        def verification_form_params
          params.require(current_form.model_name.param_key).permit(
            current_form.attribute_names.map(&:to_sym)
          )
        end

        def claim
          @claim ||= claim_scope
            .strict_loading
            .includes(eligibility: :school)
            .find_by(id: params[:claim_id])
        end
      end
    end
  end
end
