module Admin
  class DestroyTopupForm
    include ActiveModel::Model
    include ActionView::Helpers::NumberHelper

    attr_reader :topup, :removed_by

    validate :topup_not_payrolled

    def initialize(topup:, removed_by:)
      @topup = topup
      @removed_by = removed_by
    end

    def save
      return false unless valid?

      ApplicationRecord.transaction do
        topup.destroy!
        note.save!
      end

      true
    end

    private

    def note
      @note ||= topup.claim.notes.build(
        created_by: removed_by,
        body: "#{number_to_currency(topup.award_amount)} top up removed"
      )
    end

    def topup_not_payrolled
      if topup.payrolled?
        errors.add(:base, "Top up cannot be removed if payrolled")
      end
    end
  end
end
