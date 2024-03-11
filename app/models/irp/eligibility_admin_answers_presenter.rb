module Irp
  class EligibilityAdminAnswersPresenter
    include Admin::PresenterMethods

    attr_reader :eligibility

    def initialize(eligibility)
      @eligibility = eligibility
    end

    # Formats the eligibility as a list of questions and answers.
    # Suitable for playback to the service operators for them to review
    # the claim.
    #
    # Returns an array. Each element of this an array is an array of two
    # elements:
    # [0]: short question text;
    # [1]: answer text;
    def answers
      Irp::Eligibility::EDITABLE_ATTRIBUTES.map do |attribute|
        [translate_question(attribute), display_answer(attribute)]
      end
    end

    private

    def translate_question(attribute)
      translate("irp.admin.#{attribute}")
    end

    def display_answer(attribute)
      value = eligibility.public_send(attribute)
      case value
      when TrueClass
        'Yes'
      when FalseClass
        'No'
      else
        value
      end
    end
  end
end