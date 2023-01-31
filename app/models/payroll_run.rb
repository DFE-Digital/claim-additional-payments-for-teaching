class PayrollRun < ApplicationRecord
  DOWNLOAD_FILE_TIMEOUT = 30

  has_many :payments, dependent: :destroy
  has_many :claims, through: :payments

  belongs_to :created_by, class_name: "DfeSignIn::User"
  belongs_to :downloaded_by, class_name: "DfeSignIn::User", optional: true
  belongs_to :confirmation_report_uploaded_by, class_name: "DfeSignIn::User", optional: true

  validate :ensure_no_payroll_run_this_month, on: :create

  scope :this_month, -> { where(created_at: DateTime.now.all_month) }

  def total_award_amount
    payments.sum(:award_amount)
  end

  def number_of_claims_for_policy(policy)
    claims.by_policy(policy).count
  end

  def total_claim_amount_for_policy(policy)
    items = []

    payments.includes(claims: [:eligibility]).includes(:topups).map do |payment|
      payment.claims.each do |claim|
        if claim.eligibility_type == policy::Eligibility.to_s
          items << (payment.topups.present? ? payment.topups.first : claim)
        end
      end
    end

    items.sum(&:award_amount)
  end

  def self.create_with_claims!(claims, topups, attrs = {})
    ActiveRecord::Base.transaction do
      PayrollRun.create!(attrs).tap do |payroll_run|
        [claims, topups].reduce([], :concat).group_by(&:teacher_reference_number).each_value do |grouped_items|
          # associates the claim to the payment, for Topup that's its associated claim
          grouped_claims = grouped_items.map { |i| i.is_a?(Topup) ? i.claim : i }

          # associates the payment to the Topup, so we know it's payrolled
          group_topups = grouped_items.select { |i| i.is_a?(Topup) }

          award_amount = grouped_items.sum(&:award_amount)
          Payment.create!(payroll_run: payroll_run, claims: grouped_claims, topups: group_topups, award_amount: award_amount)
        end
      end
    end
  end

  def download_triggered?
    downloaded_at.present? && downloaded_by.present?
  end

  def download_available?
    download_triggered? && Time.zone.now - downloaded_at < DOWNLOAD_FILE_TIMEOUT.seconds
  end

  def confirmation_report_uploaded?
    confirmation_report_uploaded_by.present?
  end

  private

  def ensure_no_payroll_run_this_month
    errors.add(:base, "There has already been a payroll run for #{Date.today.strftime("%B")}") if PayrollRun.this_month.any?
  end
end
