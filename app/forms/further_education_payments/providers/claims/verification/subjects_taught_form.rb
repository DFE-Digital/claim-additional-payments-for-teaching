module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class SubjectsTaughtForm < BaseForm
          include ActionView::Helpers::UrlHelper
          QUALIFICATION_SEARCH_URL = "https://www.qualifications.education.gov.uk/Search?Status=Approved&Level=0,1,2,3,4&Sub=13&PageSize=10&Sort=Status"

          attribute :provider_verification_subjects_taught, :boolean

          validates(
            :provider_verification_subjects_taught,
            included: {
              in: ->(form) do
                form.provider_verification_subjects_taught_options.map(&:id)
              end,
              message: "Please confirm if they teach the eligible " \
                       "qualifications in the subject area shown"
            },
            allow_nil: :save_and_exit?
          )

          def provider_verification_subjects_taught_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def subjects_taught_description
            claim.eligibility.subjects_taught.map do |subject|
              I18n.t(
                subject,
                scope: "further_education_payments.forms.subjects_taught.options"
              )
            end
              .map(&:downcase)
              .map do |subject|
              link_to(
                "#{subject} (opens in a new tab)",
                QUALIFICATION_SEARCH_URL,
                target: "_blank"
              )
            end
              .join(", ")
          end
        end
      end
    end
  end
end
