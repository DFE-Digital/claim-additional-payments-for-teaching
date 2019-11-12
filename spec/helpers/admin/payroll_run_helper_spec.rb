require "rails_helper"

RSpec.describe Admin::PayrollRunHelper, type: :helper do
  describe "#next_payroll_file_to_cantium_due_date" do
    context "when there has not been a payroll run this month" do
      let(:third_friday_of_january_2020) { Date.new(2020, 1, 17) }

      it "returns the third to last Friday of the current month" do
        travel_to Date.new(2020, 1, 1) do
          expect(helper.next_payroll_file_to_cantium_due_date).to eql(third_friday_of_january_2020)
        end
      end
    end

    context "when the payroll run has already happended this month" do
      let(:third_friday_of_november_2019) { Date.new(2019, 11, 15) }
      let!(:payroll_run_this_month) { create(:payroll_run, created_at: Date.new(2019, 10, 1)) }

      it "returns the third to last Friday of the following month" do
        travel_to Date.new(2019, 10, 10) do
          expect(helper.next_payroll_file_to_cantium_due_date).to eql(third_friday_of_november_2019)
        end
      end
    end
  end
end
