class PayrollRun < ApplicationRecord
  has_many :payments, dependent: :destroy
  has_many :claims, through: :payments
  has_many :payment_confirmations, dependent: :destroy

  belongs_to :created_by, class_name: "DfeSignIn::User"
  belongs_to :downloaded_by, class_name: "DfeSignIn::User", optional: true
  # TODO: This relationship can be removed after a code migration is in place to
  # backfill existing payroll runs and payments with a payment confirmation
  belongs_to :confirmation_report_uploaded_by, class_name: "DfeSignIn::User", optional: true

  enum :status, %w[pending complete failed].index_with(&:itself)

  validate :ensure_no_payroll_run_this_month, on: :create

  scope :this_month, -> { where(created_at: DateTime.now.all_month) }

  def self.allow_destroy?
    ENV["ENVIRONMENT_NAME"].start_with?("review") ||
      ENV["ENVIRONMENT_NAME"] == "test" ||
      Rails.env.development?
  end

  def total_award_amount
    payments.sum(:award_amount)
  end

  def number_of_claims_for_policy(policy, filter: :all)
    line_items(policy, filter: filter).count
  end

  def total_claim_amount_for_policy(policy, filter: :all)
    line_items(policy, filter: filter).sum(&:award_amount)
  end

  def total_confirmed_payments
    payments.where.not(confirmation: nil).count
  end

  def all_payments_confirmed?
    return @all_payments_confirmed if defined?(@all_payments_confirmed)

    @all_payments_confirmed = payment_confirmations.any? && total_confirmed_payments == payments_count
  end

  def download_triggered?
    downloaded_at.present? && downloaded_by.present?
  end

  private

  def payments_count
    @payments_count ||= payments.count
  end

  class LineItem < Struct.new(:id, :award_amount, keyword_init: true); end

  def line_items(policy, filter: :all)
    scope = Claim
      .select(
        "
        DISTINCT(claims.id),
        COALESCE(topups.award_amount, eligibilities.award_amount) AS award_amount
        "
      )
      .with_award_amounts
      .left_joins(payments: :topups)
      .joins(payments: :payroll_run)
      .where(payroll_runs: {id: id})

    scope = scope.by_policy(policy) unless policy == :all

    case filter
    when :claims
      scope = scope.where(topups: {id: nil})
    when :topups
      scope = scope.where.not(topups: {id: nil})
    end

    # Claim delegates it's award amount to eligibility, so we want to return
    # a non claim object ensuring the award amount is from the topup if there
    # is one
    ActiveRecord::Base.connection.execute(scope.to_sql).map(&LineItem.method(:new))
  end

  def ensure_no_payroll_run_this_month
    errors.add(:base, "There has already been a payroll run for #{Date.today.strftime("%B")}") if PayrollRun.this_month.any?
  end
end
