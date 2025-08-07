module FurtherEducationPayments
  module Providers
    module Claims
      class VerificationsController < BaseController
        before_action :authorise_claim!
        before_action :set_form, except: %i[show]
        before_action :redirect_if_verified, except: %i[show]

        def show
          @form = Verification::CheckAnswersForm.new(
            claim: claim,
            user: current_user
          )
        end

        def edit
          render @form.template
        end

        def update
          if @form.update(verification_form_params, params[:save_and_exit])

            wizard.clear_impermissible_answers!

            flash[:success] = wizard.message if wizard.message

            if @form.read_only?
              redirect_to(
                further_education_payments_providers_claim_verification_path(claim)
              )
            elsif @form.save_and_exit?
              redirect_to(
                further_education_payments_providers_claim_information_path(
                  claim,
                  information: :progress_saved
                )
              )
            elsif wizard.completed?
              if @form.claim.eligibility.claimant_not_employed_by_college?
                redirect_to(
                  further_education_payments_providers_claim_information_path(
                    claim,
                    information: :claim_rejected
                  )
                )
              else
                redirect_to further_education_payments_providers_verified_claims_path
              end
            else
              redirect_to(
                edit_further_education_payments_providers_claim_verification_path(
                  claim,
                  slug: wizard.next_form.slug
                )
              )
            end
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

        def redirect_if_verified
          if claim.eligibility.provider_verification_completed?
            flash[:notice] = "This claim has already been verified."

            redirect_to(
              further_education_payments_providers_verified_claim_path(claim)
            )
          end
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
            current_slug: params[:slug]
          )
        end

        def permitted_attributes
          @form.attributes.keys.map do |key|
            field = @form.instance_variable_get(:@attributes)[key]

            case field.value_before_type_cast
            when Array
              {key => []}
            else
              key
            end
          end
        end

        def verification_form_params
          params
            .fetch(@form.model_name.param_key, {})
            .permit(*permitted_attributes)
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
