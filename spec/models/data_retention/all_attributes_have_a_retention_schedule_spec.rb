require "rails_helper"

RSpec.describe "All policies have a data retention schedule for all attributes" do
  let(:depricated_attributes) do
    {
      Policies::StudentLoans => ["student_loan_repayment_amount"]
    }
  end

  Policies.all.each do |policy|
    describe "#{policy} data retention schedule" do
      it "has a data retention schedule for all attributes" do
        expect(
          Object.const_defined?("Policies::#{policy}::DataRetention::RetentionSchedule")
        ).to be(true), <<~TEXT
          Policies::#{policy} does not have a data retention schedule
          Create a new `Policies::#{policy}::DataRetention::RetentionSchedule`
          class.
        TEXT

        retention_schedule = policy::DataRetention::RetentionSchedule

        Claim.column_names.each do |name|
          next if depricated_attributes[policy]&.include?(name)

          expect(
            retention_schedule.claim_attributes.keys
          ).to include(name.to_sym), <<~TEXT
            Expected Policies::#{policy}::DataRetention::RetentionSchedule to define a
            retention period for Claim attribute #{name}.
            Update Policies::#{policy}::DataRetention::RetentionSchedule.claim_attributes
            with a retention period for #{name}.
          TEXT
        end

        policy::Eligibility.column_names.each do |name|
          next if depricated_attributes[policy]&.include?(name)

          expect(
            retention_schedule.eligibility_attributes.keys
          ).to include(name.to_sym), <<~TEXT
            Expected Policies::#{policy}::DataRetention::RetentionSchedule to define a
            retention period for Eligibility attribute #{name}.
            Update
            Policies::#{policy}::DataRetention::RetentionSchedule.eligibility_attributes
            with a retention period for #{name}.
          TEXT
        end
      end
    end
  end
end
