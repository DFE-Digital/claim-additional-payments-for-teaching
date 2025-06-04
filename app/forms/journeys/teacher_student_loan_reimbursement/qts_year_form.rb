module Journeys
  module TeacherStudentLoanReimbursement
    class QtsYearForm < Form
      attribute :qts_award_year

      QTS_YEAR_OPTIONS = %w[before_cut_off_date on_or_after_cut_off_date].freeze
      private_constant :QTS_YEAR_OPTIONS

      validates :qts_award_year, presence: {message: i18n_error_message(:select_itt_year)}
      validates :qts_award_year, inclusion: {in: QTS_YEAR_OPTIONS, message: i18n_error_message(:select_itt_year)}, if: -> { qts_award_year.present? }

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          qts_award_year: qts_award_year
        )

        journey_session.save!
      end

      def radio_options
        [
          Option.new(
            id: "on_or_after_cut_off_date",
            name: t("on_or_after_cut_off_date", year: first_eligible_qts_award_year)
          ),
          Option.new(
            id: "before_cut_off_date",
            name: t("before_cut_off_date")
          )
        ]
      end

      def first_eligible_qts_award_year
        Policies::StudentLoans.first_eligible_qts_award_year.to_s(:long)
      end
    end
  end
end
