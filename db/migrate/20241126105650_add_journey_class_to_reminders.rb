class AddJourneyClassToReminders < ActiveRecord::Migration[7.2]
  def up
    add_column :reminders, :journey_class, :text
    add_index :reminders, :journey_class

    # old reminders are additional payments
    Reminder
      .where(itt_academic_year: ["2022/2023", "2023/2024", "2024/2025"])
      .update_all(journey_class: Journeys::AdditionalPaymentsForTeaching.to_s)

    # latest year
    # if itt subject must be additional payments
    Reminder
      .where(itt_academic_year: "2025/2026")
      .where("itt_subject IS NOT NULL")
      .update_all(journey_class: Journeys::AdditionalPaymentsForTeaching.to_s)

    # latest year
    # if itt subject blank
    # match emails to existing to additional payment claims
    Reminder
      .joins("JOIN claims on claims.email_address = reminders.email_address")
      .where(itt_academic_year: "2025/2026")
      .where(itt_subject: nil)
      .where(claims: {eligibility_type: ["Policies::LevellingUpPremiumPayments::Eligibility", "Policies::EarlyCareerPayments::Eligibility"]})
      .update_all(journey_class: Journeys::AdditionalPaymentsForTeaching.to_s)

    # latest year
    # if itt subject blank
    # match emails to existing to tslr payment claims
    Reminder
      .joins("JOIN claims on claims.email_address = reminders.email_address")
      .where(itt_academic_year: "2025/2026")
      .where(itt_subject: nil)
      .where(claims: {eligibility_type: ["Policies::StudentLoans::Eligibility"]})
      .update_all(journey_class: Journeys::TeacherStudentLoanReimbursement.to_s)

    # assume remaining to be FE
    Reminder
      .where(journey_class: nil)
      .update_all(journey_class: Journeys::FurtherEducationPayments.to_s)

    change_column_null :reminders, :journey_class, false
  end

  def down
    remove_column :reminders, :journey_class
  end
end
