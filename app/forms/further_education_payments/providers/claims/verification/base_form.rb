module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class BaseForm
          include ActiveModel::Model
          include ActiveModel::Attributes
          include ActiveModel::Validations::Callbacks

          before_validation do
            attributes.each do |k, v|
              public_send("#{k}=", nil) if v == ""
            end
          end

          attr_reader :claim, :user
          delegate :eligibility, to: :claim

          def initialize(claim:, user:, params: {})
            @claim = claim
            @user = user

            exisiting_attributes = claim.eligibility.attributes.slice(
              *self.class.attribute_names
            )

            super(params.reverse_merge(exisiting_attributes).with_indifferent_access)
          end

          def template
            slug
          end

          def slug
            model_name.element.remove("_form")
          end

          def incomplete?
            dup.invalid?
          end

          def update(params, save_and_exit = false)
            @save_and_exit = save_and_exit
            assign_attributes(params)
            save
          end

          def save
            return false unless valid?

            if claim.eligibility.provider_verification_started_at.nil?
              claim.eligibility.provider_verification_started_at = Time.current
              claim.eligibility.provider_assigned_to_id = user.id
            end

            attributes_to_save.each do |attribute|
              claim.eligibility.public_send("#{attribute}=", send(attribute))
            end

            claim.eligibility.save!

            true
          end

          def clear_answers!
            attributes_to_clear.each do |attribute|
              case @attributes[attribute].value_before_type_cast
              when Array
                claim.eligibility.public_send("#{attribute}=", [])
              else
                claim.eligibility.public_send("#{attribute}=", nil)
              end
            end

            claim.eligibility.save!
          end

          def provider
            claim.eligibility.school
          end

          def provider_name
            provider.name
          end

          def claimant_name
            claim.full_name
          end

          def save_and_exit?
            !!@save_and_exit
          end

          def read_only?
            false
          end

          private

          def attributes_to_clear
            attributes_to_save
          end

          def attributes_to_save
            attribute_names.select do |name|
              name.to_s.start_with?("provider_verification_")
            end
          end
        end
      end
    end
  end
end
