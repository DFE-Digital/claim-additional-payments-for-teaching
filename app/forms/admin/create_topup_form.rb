module Admin
  class CreateTopupForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActionView::Helpers::NumberHelper

    def self.model_name
      ActiveModel::Name.new(self, nil, "Topup")
    end

    attr_reader :claim, :created_by

    attribute :award_amount, :decimal

    validate :topup_is_valid
    validate :note_is_valid

    def initialize(claim:, created_by:, params: {})
      @claim = claim
      @created_by = created_by

      super(params)
    end

    def save
      return false unless valid?

      ApplicationRecord.transaction do
        topup.save!
        note.save!
      end

      true
    end

    private

    def topup
      @topup ||= claim.topups.build(
        created_by: created_by,
        award_amount: award_amount
      )
    end

    def note
      @note ||= claim.notes.build(
        created_by: created_by,
        body: "#{number_to_currency(award_amount)} top up added"
      )
    end

    def topup_is_valid
      errors.merge!(topup.tap(&:validate).errors)
    end

    def note_is_valid
      errors.merge!(note.tap(&:validate).errors)
    end
  end
end
