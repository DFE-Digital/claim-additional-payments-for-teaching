require "faker"
require Rails.application.root.join("lib", "factory_helpers")
class GeneratePayrollRun2 < ActiveRecord::Migration[7.0]
  def change
    PayrollRun.destroy_all

    FactoryHelpers.create_factory_registry
    FactoryHelpers.reset_factory_registry

    FactoryBot.create(
      :payroll_run,
      claims_counts: {
        Policies::StudentLoans => 600,
        Policies::EarlyCareerPayments => 900,
        [Policies::EarlyCareerPayments, Policies::StudentLoans] => 300,
        Policies::FurtherEducationPayments => 600,
        Policies::InternationalRelocationPayments => 300,
        Policies::LevellingUpPremiumPayments => 301
      }
    )
  end
end
