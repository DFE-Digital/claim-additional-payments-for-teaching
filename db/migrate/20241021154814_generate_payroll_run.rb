require "faker"
require Rails.application.root.join("lib", "factory_helpers")

class GeneratePayrollRun < ActiveRecord::Migration[7.0]
  def change
    PayrollRun.destroy_all

    FactoryHelpers.create_factory_registry
    FactoryHelpers.reset_factory_registry

    ApplicationRecord.transaction do
      FactoryBot.create(
        :payroll_run,
        claims_counts: {
          Policies::StudentLoans => 600,
          Policies::EarlyCareerPayments => 900,
          [Policies::EarlyCareerPayments, Policies::StudentLoans] => 300,
          Policies::FurtherEducationPayments => 600,
          Policies::InternationalRelocationPayments => 300,
          Policies::LevellingUpPremiumPayments => 300
        }
      )
    end
  end
end
