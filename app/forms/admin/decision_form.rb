module Admin
  class DecisionForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :claim, :qa, :current_admin

    attribute :approved, :boolean
    attribute :notes, :string
    attribute :rejected_reasons, default: []

    validates :approved,
      inclusion: {
        in: [true, false],
        message: "Select if you approve or reject the claim"
      }

    validates :notes,
      presence: {
        message: "You must enter a reason for rejecting this claim in the decision note"
      },
      if: proc { |form| form.rejected_reasons.include?("other") }

    validate :validate_rejected_reasons_permitted
    validate :validate_payroll_gender_present_for_approval
    validate :validate_no_payment_prevention_for_approval
    validate :validate_not_decided

    def initialize(claim:, qa:, current_admin:, params: {})
      @claim = claim
      @qa = qa
      @current_admin = current_admin

      super(params)
    end

    def save
      return false if invalid?
      return false if decision.invalid?

      ActiveRecord::Base.transaction do
        decision.save!

        if qa?
          claim.previous_decision.update!(undone: true)
          claim.update!(qa_completed_at: Time.zone.now)
        elsif claim.flaggable_for_qa?
          claim.update!(qa_required: true)
          claim.notes.create!(body: "This claim has been marked for a quality assurance review")
        end

        send_claim_result_email

        true
      end
    rescue ActiveRecord::RecordInvalid
      false
    end

    def heading
      if qa?
        "Quality assurance decision"
      else
        "Claim decision"
      end
    end

    def qa?
      qa
    end

    def checkbox_options
      ::Decision.rejected_reasons_for(claim).map do |reason|
        Form::Option.new(
          id: reason,
          name: I18n.t("#{claim.policy.locale_key}.admin.decision.rejected_reasons.#{reason}")
        )
      end
    end

    def approve_label_text
      if qa? && claim.rejected?
        "Claim meets eligibility criteria. Approve claim for payment"
      else
        "Approve"
      end
    end

    def reject_label_text
      if qa? && claim.rejected?
        "Claim does not meet eligibility criteria. Reject claim"
      else
        "Reject"
      end
    end

    def approved_button_disabled?
      !claim.approvable?(current_admin:)
    end

    def reject_button_disabled?
      !claim.rejectable?(current_admin:)
    end

    private

    def validate_not_decided
      return if qa?

      if @claim.latest_decision.present?
        errors.add(:approved, "Claim outcome already decided")
      end
    end

    def validate_no_payment_prevention_for_approval
      if approve? && claims_preventing_payment_finder.claims_preventing_payment.any?
        errors.add(:approved, "Claim cannot be approved because there are inconsistent claims")
      end
    end

    def approve?
      approved == true
    end

    def reject?
      approved == false
    end

    def validate_payroll_gender_present_for_approval
      if approve? && claim.payroll_gender_missing?
        errors.add(:approved, "Claim cannot be approved. Payroll gender missing")
      end
    end

    def validate_rejected_reasons_permitted
      if reject? && rejected_reasons.reject(&:blank?).empty?
        errors.add(:rejected_reasons, "Select at least one rejection reason")
      end

      # TODO: here check reasons against policy
    end

    def send_claim_result_email
      return if claim.awaiting_qa?

      claim.policy.mailer.approved(claim).deliver_later if claim.latest_decision.approved?

      if claim.latest_decision.rejected? && claim.email_address.present?
        ClaimMailer.rejected(claim).deliver_later
      end

      if claim.latest_decision.rejected? && claim.has_early_years_policy?
        ClaimMailer.rejected_provider_notification(claim).deliver_later
      end
    end

    def decision
      @decision ||= claim
        .decisions
        .build(attributes_for_decision) do |d|
          d.created_by = current_admin
        end
    end

    def attributes_for_decision
      {
        approved:,
        notes:,
        rejected_reasons: rejected_reasons_hash
      }
    end

    def rejected_reasons_hash
      rejected_reasons
        .reject(&:blank?)
        .map { |reason| [reason, "1"] }.to_h
    end

    def claims_preventing_payment_finder
      @claims_preventing_payment_finder ||= Claim::ClaimsPreventingPaymentFinder.new(claim)
    end
  end
end
