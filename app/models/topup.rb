class Topup < ApplicationRecord
  include ActiveSupport::NumberHelper

  MIN_AWARD_AMOUNT = 1
  MAX_AWARD_AMOUNT = 3_000

  belongs_to :claim
  belongs_to :payment, optional: true

  scope :payrollable, -> { includes(:claim).where(payment: nil) }

  validates :award_amount, presence: {message: "Enter top up amount"}
  validate :award_amount_must_be_in_range

  delegate :teacher_reference_number, to: :claim

  def self.payrollable_claims
    payrollable.map(&:claim)
  end

  def payrolled?
    payment.present?
  end

  private

  def award_amount_must_be_in_range
    return unless award_amount.present?

    unless award_amount.between?(MIN_AWARD_AMOUNT, MAX_AWARD_AMOUNT)
      errors.add(:award_amount, "Enter a positive amount up to #{number_to_currency(MAX_AWARD_AMOUNT)} (inclusive)")
    end
  end
end
