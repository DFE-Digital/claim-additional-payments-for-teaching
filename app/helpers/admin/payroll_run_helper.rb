module Admin
  module PayrollRunHelper
    def next_payroll_file_to_cantium_due_date
      next_payrollable_month = PayrollRun.this_month.exists? ? Date.today.next_month.all_month : Date.today.all_month
      all_fridays_in_month(next_payrollable_month)[-3]
    end

    private

    def all_fridays_in_month(month)
      month.select { |day| day.friday? }
    end
  end
end
