module Policies
  module LevellingUpPremiumPayments
    class Eligibility < ApplicationRecord
      def policy
        Policies::LevellingUpPremiumPayments
      end

      include ActiveSupport::NumberHelper

      self.table_name = "levelling_up_premium_payments_eligibilities"
      has_one :claim, as: :eligibility, inverse_of: :eligibility
      belongs_to :current_school, optional: true, class_name: "School"

      validate :award_amount_must_be_in_range, on: :amendment

      delegate :name, to: :current_school, prefix: true, allow_nil: true

      AMENDABLE_ATTRIBUTES = [:award_amount].freeze

      FIRST_ITT_AY = "2017/2018"
      LAST_POLICY_YEAR = "2024/2025"

      # Generates an object similar to
      # {
      #   <AcademicYear:0x00007f7d87429238 @start_year=2020, @end_year=2021> => "2020/2021",
      #   <AcademicYear:0x00007f7d87429210 @start_year=2021, @end_year=2022> => "2021/2022",
      #   <AcademicYear:0x00007f7d87428c98 @start_year=nil, @end_year=nil> => "None"
      # }
      # Note: LUPP policy began in academic year 2022/23 so the persisted options
      # should include 2017/18 onward.
      # In test environment the journey configuration record may not exist.
      # This can't be dynamic on Journeys::Configuration current_academic_year because changing the year means the 5 year window changes
      # and the enums would be stale until after a server restart.
      # Make all valid ITT values based on the last known policy year.
      ITT_ACADEMIC_YEARS =
        (AcademicYear.new(FIRST_ITT_AY)...AcademicYear.new(LAST_POLICY_YEAR)).each_with_object({}) do |year, hsh|
          hsh[year] = AcademicYear::Type.new.serialize(year)
        end.merge({AcademicYear.new => AcademicYear::Type.new.serialize(AcademicYear.new)})

      enum itt_academic_year: ITT_ACADEMIC_YEARS

      enum qualification: {
        postgraduate_itt: 0,
        undergraduate_itt: 1,
        assessment_only: 2,
        overseas_recognition: 3
      }

      enum eligible_itt_subject: {
        chemistry: 0,
        foreign_languages: 1,
        mathematics: 2,
        physics: 3,
        none_of_the_above: 4,
        computing: 5
      }, _prefix: :itt_subject

      private

      def award_amount_must_be_in_range
        claim_year = Journeys.for_policy(policy).configuration.current_academic_year
        max = LevellingUpPremiumPayments::Award.where(academic_year: claim_year.to_s).maximum(:award_amount)

        unless award_amount&.between?(1, max)
          errors.add(:award_amount, "Enter a positive amount up to #{number_to_currency(max)} (inclusive)")
        end
      end
    end
  end
end
