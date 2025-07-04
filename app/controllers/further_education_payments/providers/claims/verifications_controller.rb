module FurtherEducationPayments
  module Providers
    module Claims
      class VerificationsController < BaseController
        before_action :authorise_claim!
        before_action :set_form

        def edit
          render @form.template
        end

        def update
          if @form.update(verification_form_params)

            wizard.clear_impermissible_answers!

            redirect_to(
              edit_further_education_payments_providers_claim_verification_path(
                claim,
                slug: wizard.next_form.slug
              )
            )
          else
            render @form.template, status: :unprocessable_entity
          end
        end

        private

        def authorise_claim!
          claim
        rescue ActiveRecord::RecordNotFound
          redirect_to(
            further_education_payments_providers_authorisation_failure_path(
              reason: :claim_not_found
            )
          )
        end

        def set_form
          @form = wizard.current_form
        end

        def backlink_path
          previous_form = wizard.previous_form

          edit_further_education_payments_providers_claim_verification_path(
            claim,
            slug: previous_form.slug
          )
        end
        helper_method :backlink_path

        def wizard
          Verification::Wizard.new(
            claim: claim,
            user: current_user,
            current_slug: params[:slug] || Verification::Wizard.first_slug
          )
        end

        def verification_form_params
          params.require(@form.model_name.param_key).permit(
            @form.attribute_names.map(&:to_sym)
          )
        end

        def claim
          @claim ||= claim_scope
            .strict_loading
            .includes(eligibility: :school)
            .find(params[:claim_id])
        end
      end
    end
  end
end
