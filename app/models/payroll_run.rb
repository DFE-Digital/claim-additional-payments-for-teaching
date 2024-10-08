class PayrollRun < ApplicationRecord
  MAX_BATCH_SIZE = 1000
  MAX_MONTHLY_PAYMENTS = 3000

  has_many :payments, dependent: :destroy
  has_many :claims, through: :payments
  has_many :payment_confirmations, dependent: :destroy

  belongs_to :created_by, class_name: "DfeSignIn::User"
  belongs_to :downloaded_by, class_name: "DfeSignIn::User", optional: true
  # TODO: This relationship can be removed after a code migration is in place to
  # backfill existing payroll runs and payments with a payment confirmation
  belongs_to :confirmation_report_uploaded_by, class_name: "DfeSignIn::User", optional: true

  validate :ensure_no_payroll_run_this_month, on: :create
  validate :ensure_within_max_monthly_payments, on: :create

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

  def payments_in_batches
    payments.includes(:claims).find_in_batches(batch_size: MAX_BATCH_SIZE)
  end

  def total_batches
    (payments.count / MAX_BATCH_SIZE.to_f).ceil
  end

  def total_confirmed_payments
    payments.where.not(confirmation: nil).count
  end

  def all_payments_confirmed?
    payment_confirmations.any? && total_confirmed_payments == payments.count
  end

  def self.create_with_claims!(claims, topups, attrs = {})
    ActiveRecord::Base.transaction do
      PayrollRun.create!(attrs).tap do |payroll_run|
        [claims, topups].reduce([], :concat).group_by { |obj| group_by_field(obj) }.each_value do |grouped_items|
          # associates the claim to the payment, for Topup that's its associated claim
          grouped_claims = grouped_items.map { |i| i.is_a?(Topup) ? i.claim : i }

          # associates the payment to the Topup, so we know it's payrolled
          group_topups = grouped_items.select { |i| i.is_a?(Topup) }

          award_amount = grouped_items.map(&:award_amount).compact.sum(0)
          Payment.create!(payroll_run: payroll_run, claims: grouped_claims, topups: group_topups, award_amount: award_amount)
        end
      end
    end
  end

  def self.group_by_field(obj)
    obj.national_insurance_number
  end

  def download_triggered?
    downloaded_at.present? && downloaded_by.present?
  end

  private

  def line_items(policy, filter: :all)
    @items = []

    payments.includes(claims: [:eligibility]).includes(:topups).map do |payment|
      payment.claims.each do |claim|
        if policy == :all || claim.eligibility_type == policy::Eligibility.to_s
          topup_claim_ids = payment.topups.pluck(:claim_id)
          line_item = topup_claim_ids.include?(claim.id) ? payment.topups.find { |t| t.claim_id == claim.id } : claim
          case filter
          when :all
            @items << line_item
          when :claims
            @items << line_item if line_item.is_a?(Claim)
          when :topups
            @items << line_item if line_item.is_a?(Topup)
          end
        end
      end
    end

    @items
  end

  def ensure_no_payroll_run_this_month
    errors.add(:base, "There has already been a payroll run for #{Date.today.strftime("%B")}") if PayrollRun.this_month.any?
  end

  def ensure_within_max_monthly_payments
    errors.add(:base, "This payroll run exceeds #{MAX_MONTHLY_PAYMENTS} payments") if payments.size > MAX_MONTHLY_PAYMENTS
  end
end
