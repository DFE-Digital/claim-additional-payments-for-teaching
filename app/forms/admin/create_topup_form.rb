module Admin
  class CreateTopupForm
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActionView::Helpers::NumberHelper

    def self.model_name
      ActiveModel::Name.new(self, nil, "Topup")
    end

    STEPS = %i[award_amount confirmation].freeze

    attribute :step, default: STEPS.first

    attr_reader :claim, :created_by

    attribute :award_amount, :decimal
    attribute :confirmation, :boolean, default: false

    with_options on: :award_amount do
      validate :topup_is_valid
      validate :note_is_valid
    end

    with_options on: :confirmation do
      validates :confirmation, acceptance: true
    end

    def initialize(claim:, created_by:, params: {})
      @claim = claim
      @created_by = created_by

      super(params)
    end

    def step
      super.to_sym
    end

    def next_step
      STEPS[STEPS.index(step) + 1]
    end

    def complete?
      STEPS.all? { |step| dup.valid?(step) }
    end

    def save!
      raise ActiveRecord::RecordInvalid unless complete?

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
