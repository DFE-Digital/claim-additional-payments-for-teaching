class ChangeJourneyConfigurations < ActiveRecord::Migration[7.0]
  def up
    execute("ALTER TABLE journey_configurations DROP CONSTRAINT journey_configurations_pkey;")

    add_column(:journey_configurations, :routing_name, :string)

    Journeys::Configuration.where("? = ANY (policy_types)", "EarlyCareerPayments").update_all(routing_name: Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME)
    Journeys::Configuration.where("? = ANY (policy_types)", "StudentLoans").update_all(routing_name: Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME)

    execute "ALTER TABLE journey_configurations ADD PRIMARY KEY (routing_name);"

    remove_column(:journey_configurations, :id)
    remove_column(:journey_configurations, :policy_types)
  end

  def down
    execute("ALTER TABLE journey_configurations DROP CONSTRAINT journey_configurations_pkey;")

    add_column(:journey_configurations, :id, :uuid, default: -> { "gen_random_uuid()" })
    add_column(:journey_configurations, :policy_types, :text, array: true, default: [])

    Journeys::Configuration.where(routing_name: Journeys::AdditionalPaymentsForTeaching::ROUTING_NAME).update_all(policy_types: [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments])
    Journeys::Configuration.where(routing_name: Journeys::TeacherStudentLoanReimbursement::ROUTING_NAME).update_all(policy_types: [Policies::StudentLoans])

    remove_column(:journey_configurations, :routing_name, :string)

    execute "ALTER TABLE journey_configurations ADD PRIMARY KEY (id);"
    add_index(:journey_configurations, :policy_types)
  end
end
