class PaymentConfirmationUpload
  attr_reader :payroll_run, :csv, :csv_file, :updated_payment_ids, :errors, :admin_user

  def initialize(payroll_run, csv_file, admin_user)
    @payroll_run = payroll_run
    @errors = []
    @csv_file = csv_file
    @csv = PaymentConfirmationCsv.new(csv_file)
    @line_number = 1
    @updated_payment_ids = Set.new
    @admin_user = admin_user
    validate
  end

  def ingest
    return if errors.any?

    ActiveRecord::Base.transaction do
      payments = []

      file_upload = FileUpload.create!(
        uploaded_by: admin_user,
        body: File.read(csv_file),
        target_data_model: PaymentConfirmation.to_s
      )

      confirmation = payroll_run.payment_confirmations.create!(created_by: admin_user, file_upload:)

      csv.rows.each do |row|
        @line_number += 1

        next if row.fields.all? { |cell| cell.nil? }

        payment = fetch_payment_by_id(row["Payment ID"])
        if payment
          update_payment_fields(payment, confirmation, row)
          payments << payment
        end
      end

      file_upload.completed_processing!

      raise ActiveRecord::Rollback if errors.any?

      payments.each do |payment|
        PaymentMailer.confirmation(payment).deliver_later
      end
    end
  end

  private

  attr_reader :line_number

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

  def fetch_payment_by_id(id)
    payment = payroll_run.payments.unconfirmed.find_by(id:)

    return payment if payment

    if updated_payment_ids.include?(id)
      errors.append("The payment with ID #{id} is repeated at line #{line_number}")
      return
    end

    errors.append("The CSV file contains a payment that is already confirmed or not part of the payroll run at line #{line_number}")
    nil
  end

  def update_payment_fields(payment, confirmation, row)
    payment.payroll_reference = row["Payroll Reference"]
    payment.gross_value = cast_as_numeric(row["Gross Value"]).to_d + cast_as_numeric(row["Employers NI"]).to_d
    payment.national_insurance = cast_as_numeric(row["NI"])
    payment.employers_national_insurance = cast_as_numeric(row["Employers NI"])
    payment.student_loan_repayment = cast_as_numeric(row["Student Loans"])
    payment.postgraduate_loan_repayment = cast_as_numeric(row["Postgraduate Loans"])
    payment.tax = cast_as_numeric(row["Tax"])
    payment.net_pay = cast_as_numeric(row["Net Pay"])
    payment.gross_pay = cast_as_numeric(row["Gross Value"])
    payment.scheduled_payment_date = cast_as_date(row["Payment Date"])

    payment.confirmation = confirmation

    if payment.save(context: :upload)
      updated_payment_ids.add(payment.id)
    else
      errors.append("The claim at line #{line_number} has invalid data - #{payment.errors.full_messages.to_sentence}")
    end
  end

  def cast_as_numeric(number)
    number&.delete(",")
  end

  def cast_as_date(string)
    Date.strptime(string, I18n.t("date.formats.day_month_year"))
  rescue TypeError, Date::Error
    nil
  end
end
