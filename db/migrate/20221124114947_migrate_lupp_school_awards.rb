class MigrateLuppSchoolAwards < ActiveRecord::Migration[6.1]
  def up
    # TODO: This method should be removed some time after this migration is run
    if LevellingUpPremiumPayments::Award.respond_to?(:urn_to_award_amount_in_pounds_for_2022_to_2023, true)
      academic_year = AcademicYear.new(2022)

      LevellingUpPremiumPayments::Award.send(:urn_to_award_amount_in_pounds_for_2022_to_2023).each_pair do |school_urn, award_amount|
        LevellingUpPremiumPayments::Award.create!(
          academic_year: academic_year,
          school_urn: school_urn,
          award_amount: award_amount
        )
      end
    end
  end

  # Do nothing; we don't want to destroy this data
  def down
  end
end
