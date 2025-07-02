module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class BaseForm
          include ActiveModel::Model
          include ActiveModel::Attributes

          attr_reader :claim, :user
          delegate :eligibility, to: :claim

          def initialize(claim:, user:, params: {})
            @claim = claim
            @user = user

            super(params)
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

          def update(params)
            assign_attributes(params)
            save
          end

          def save
            return false unless valid?

            attributes_to_save.each do |attribute|
              claim.eligibility.send("#{attribute}=", send(attribute))
            end

            claim.eligibility.save!

            true
          end

          def clear_answers!
            attributes_to_save.each do |attribute|
              claim.eligibility.send("#{attribute}=", nil)
            end

            claim.eligibility.save!
          end

          def provider
            claim.eligibility.school
          end

          private

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
