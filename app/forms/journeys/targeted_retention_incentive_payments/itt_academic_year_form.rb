module Journeys
  module TargetedRetentionIncentivePayments
    class IttAcademicYearForm < Form
      attribute :itt_academic_year_string, :string

      validates :itt_academic_year_string, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: ->(form, _) do
          form.t([:errors, :inclusion, form.answers.qualification])
        end
      }

      # Issue is
      # * itt_academic_year is type cast to an AY in session answers
      # * navigator calls this class with the session answers
      # * an AY is not one of the option ids (they're strings)
      # * this class does work on form submission from the html.
      # Other issue is
      # * If we type cast itt_academic_year, how does choosing "None of the
      # above" work? How does this work on AddionalPayments?
      # On AP it kicks you out of the journey straight away, the AY is a null
      # AY. We should probably handle this better and store a selected AY year
      # as a string and convert to AY when we need to with an itt_academic_year
      # method. Tricky bit will be in the submission form.
      def save
        return false unless valid?

        # Pretty sure the navigator handles this?
        if reset_dependent_answers?
          journey_session.answers.assign_attributes(eligible_itt_subject: nil)
        end

        journey_session.answers.assign_attributes(
          itt_academic_year_string: itt_academic_year_string
        )

        journey_session.save!
      end

      def radio_options
        AdditionalPaymentsForTeaching.selectable_itt_years_for_claim_year(
          journey.configuration.current_academic_year
        )
        .map { Option.new(id: it.to_s, name: it.to_s(:long)) }
        .push(none_of_the_above)
      end

      def none_of_the_above
        Option.new(
          id: NONE_OF_THE_ABOVE_ACADEMIC_YEAR,
          name: "None of the above"
        )
      end

      private

      def itt_academic_year_changed?
        answers.itt_academic_year_string != itt_academic_year_string
      end

      def reset_dependent_answers?
        itt_academic_year_changed? && !answers.qualifications_details_check?
      end
    end
  end
end

