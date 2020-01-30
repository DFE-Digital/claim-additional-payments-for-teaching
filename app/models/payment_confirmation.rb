class PaymentConfirmation
  attr_reader :payroll_run, :csv, :updated_payment_ids, :errors, :admin_user_id

  def initialize(payroll_run, csv_file, admin_user_id)
    @payroll_run = payroll_run
    @errors = []
    @csv = PaymentConfirmationCsv.new(csv_file)
    @line_number = 1
    @updated_payment_ids = Set.new
    @admin_user_id = admin_user_id
    validate
  end

  def ingest
    return if errors.any?

    ActiveRecord::Base.transaction do
      csv.rows.each do |row|
        @line_number += 1
        payment = fetch_payment_by_id(row["Payment ID"])
        update_payment_fields(payment, row) if payment
      end

      payroll_run.update!(
        confirmation_report_uploaded_by: admin_user_id,
        scheduled_payment_date: scheduled_payment_date
      )

      if errors.empty?
        payroll_run.payments.each do |payment|
          PaymentMailer.confirmation(payment).deliver_later
        end

        RecordOrUpdateGeckoboardDatasetJob.perform_later(payroll_run.claims.pluck(:id))
      else
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def scheduled_payment_date
    Date.today.next_occurring(:friday)
  end

  def validate
    if csv.errors.empty?
      check_payroll_run
      check_for_missing_payments
    else
      @errors = csv.errors
    end
  end

  def check_payroll_run
    errors.append("A Payment Confirmation Report has already been uploaded for this payroll run") if payroll_run.confirmation_report_uploaded?
  end

  def check_for_missing_payments
    missing_payment_ids = payroll_run.payments.map { |payment| payment.id } - csv.rows.map { |c| c["Payment ID"] }
    missing_payment_ids.each do |id|
      errors.append("Payment ID #{id} is missing from the file. Please check with Cantium to see if there is a problem with this payment. You may need to remove some payments from the Payroll Run then try uploading it again")
    end
  end

  def fetch_payment_by_id(id)
    payment = payroll_run.payments.detect { |payment| payment.id == id }

    if payment
      payment
    else
      errors.append("The CSV file contains a payment that is not part of the payroll run at line #{@line_number}")
      nil
    end
  end

  def update_payment_fields(payment, row)
    if updated_payment_ids.include?(payment.id)
      errors.append("The payment with ID #{payment.id} is repeated at line #{@line_number}")
      return
    end

    payment.payroll_reference = row["Payroll Reference"]
    payment.gross_value = row["Gross Value"]
    payment.national_insurance = row["NI"]
    payment.employers_national_insurance = row["Employers NI"]
    payment.student_loan_repayment = row["Student Loans"]
    payment.tax = row["Tax"]
    payment.net_pay = row["Net Pay"]
    payment.gross_pay = row["Gross Value"].to_d - row["Employers NI"].to_d

    if payment.save(context: :upload)
      updated_payment_ids.add(payment.id)
    else
      errors.append("The claim at line #{@line_number} has invalid data")
    end
  end
end
