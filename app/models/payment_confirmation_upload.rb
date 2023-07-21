class PaymentConfirmationUpload
  attr_reader :payroll_run, :csv, :updated_payment_ids, :errors, :admin_user

  def initialize(payroll_run, csv_file, admin_user)
    @payroll_run = payroll_run
    @errors = []
    @csv = PaymentConfirmationCsv.new(csv_file)
    @line_number = 1
    @updated_payment_ids = Set.new
    @scheduled_payment_date = nil
    @admin_user = admin_user
    validate
  end

  def ingest
    return if errors.any?

    ActiveRecord::Base.transaction do
      payments = []

      csv.rows.each do |row|
        @line_number += 1
        payment = fetch_payment_by_id(row["Payment ID"])
        if payment
          update_payment_fields(payment, row)
          parse_payment_date(row)
          payments << payment
        end
      end

      raise ActiveRecord::Rollback if errors.any?

      payroll_run.payment_confirmations.create!(
        scheduled_payment_date: scheduled_payment_date,
        payments: payments,
        created_by: admin_user
      )

      payments.each do |payment|
        PaymentMailer.confirmation(payment).deliver_later
      end
    end
  end

  private

  attr_reader :line_number, :scheduled_payment_date

  def validate
    if csv.errors.empty?
      check_for_already_confirmed
    else
      @errors = csv.errors
    end
  end

  def check_for_already_confirmed
    errors.append("A Payment Confirmation Report for all payments has already been uploaded for this payroll run") if payroll_run.all_payments_confirmed?
  end

  def parse_payment_date(row)
    @scheduled_payment_date = begin
      Date.strptime(row["Payment Date"], I18n.t("date.formats.day_month_year"))
    rescue TypeError, Date::Error
      errors.append("Payment Date is not in the DD/MM/YYYY format at line #{line_number}")
      nil
    end
  end

  def fetch_payment_by_id(id)
    payment = payroll_run.payments.unconfirmed.detect { |payment| payment.id == id }

    if payment
      payment
    else
      errors.append("The CSV file contains a payment that is already confirmed or not part of the payroll run at line #{line_number}")
      nil
    end
  end

  def update_payment_fields(payment, row)
    if updated_payment_ids.include?(payment.id)
      errors.append("The payment with ID #{payment.id} is repeated at line #{line_number}")
      return
    end

    payment.payroll_reference = row["Payroll Reference"]
    payment.gross_value = cast_as_numeric(row["Gross Value"]).to_d + cast_as_numeric(row["Employers NI"]).to_d
    payment.national_insurance = cast_as_numeric(row["NI"])
    payment.employers_national_insurance = cast_as_numeric(row["Employers NI"])
    payment.student_loan_repayment = cast_as_numeric(row["Student Loans"])
    payment.postgraduate_loan_repayment = cast_as_numeric(row["Postgraduate Loans"])
    payment.tax = cast_as_numeric(row["Tax"])
    payment.net_pay = cast_as_numeric(row["Net Pay"])
    payment.gross_pay = cast_as_numeric(row["Gross Value"])

    if payment.save(context: :upload)
      updated_payment_ids.add(payment.id)
    else
      errors.append("The claim at line #{line_number} has invalid data - #{payment.errors.full_messages.to_sentence}")
    end
  end

  def cast_as_numeric(number)
    number&.gsub(",", "")
  end
end
