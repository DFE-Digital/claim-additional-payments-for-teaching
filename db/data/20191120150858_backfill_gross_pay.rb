class BackfillGrossPay < ActiveRecord::Migration[6.0]
  def up
    Payment.where(gross_pay: nil).where.not(gross_value: nil).each do |payment|
      payment.update_attribute(:gross_pay, payment.gross_value - payment.employers_national_insurance)
    end
  end

  def down
    Payment.update_all(gross_pay: nil)
  end
end
