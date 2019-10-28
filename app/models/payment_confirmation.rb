class PaymentConfirmation
  attr_reader :payroll_run, :csv, :updated_claim_references, :errors, :admin_user_id

  def initialize(payroll_run, csv_file, admin_user_id)
    @payroll_run = payroll_run
    @errors = []
    @csv = PaymentConfirmationCsv.new(csv_file)
    @line_number = 1
    @updated_claim_references = Set.new
    @admin_user_id = admin_user_id
    validate
  end

  def ingest
    return if errors.any?

    ActiveRecord::Base.transaction do
      csv.rows.each do |row|
        @line_number += 1
        payment = fetch_payment_by_reference(row["Claim ID"])
        update_payment_fields(payment, row) if payment
      end

      payroll_run.update!(confirmation_report_uploaded_by: admin_user_id)

      if errors.empty?
        payroll_run.claims.each do |claim|
          ClaimMailer.payment_confirmation(claim, payment_date_timestamp).deliver_later
        end
      else
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def payment_date_timestamp
    Date.today.next_occurring(:friday).to_time.to_i
  end

  def validate
    if csv.errors.empty?
      check_payroll_run
      check_for_missing_claims
    else
      @errors = csv.errors
    end
  end

  def check_payroll_run
    errors.append("A Payment Confirmation Report has already been uploaded for this payroll run") if payroll_run.confirmation_report_uploaded_by
  end

  def check_for_missing_claims
    missing_claims_references = payroll_run.claims.map(&:reference) - csv.rows.map { |c| c["Claim ID"] }
    missing_claims_references.each do |claim|
      errors.append("The claim ID #{claim} is missing from the CSV")
    end
  end

  def fetch_payment_by_reference(reference)
    claim = payroll_run.claims.detect { |claim| claim.reference == reference }

    if claim
      claim.payment
    else
      errors.append("The CSV file contains a claim that is not part of the payroll run at line #{@line_number}")
      nil
    end
  end

  def update_payment_fields(payment, row)
    if updated_claim_references.include?(payment.claim.reference)
      errors.append("The claim ID #{payment.claim.reference} is repeated at line #{@line_number}")
      return
    end

    payment.payroll_reference = row["Payroll Reference"]
    payment.gross_value = row["Gross Value"]
    payment.national_insurance = row["NI"]
    payment.employers_national_insurance = row["Employers NI"]
    payment.student_loan_repayment = row["Student Loans"]
    payment.tax = row["Tax"]
    payment.net_pay = row["Net Pay"]

    if payment.save(context: :upload)
      updated_claim_references.add(payment.claim.reference)
    else
      errors.append("The claim at line #{@line_number} has invalid data")
    end
  end
end
