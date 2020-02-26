class Admin::DecisionsController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim
  before_action :reject_decided_claims
  before_action :reject_missing_payroll_gender, only: [:create]
  before_action :reject_if_claims_preventing_payment, only: [:create]

  def new
    @decision = Decision.new
  end

  def create
    @decision = @claim.build_decision(decision_params.merge(created_by: admin_user))
    if @decision.save
      send_claim_result_email
      RecordOrUpdateGeckoboardDatasetJob.perform_later([@claim.id])
      redirect_to admin_claims_path, notice: "Claim has been #{@claim.decision.result} successfully"
    else
      @claims_preventing_payment = claims_preventing_payment_finder.claims_preventing_payment
      render "new"
    end
  end

  private

  def load_claim
    @claim = Claim.find(params[:claim_id])
    @matching_claims = Claim::MatchingAttributeFinder.new(@claim).matching_claims
  end

  def claims_preventing_payment_finder
    @claims_preventing_payment_finder ||= Claim::ClaimsPreventingPaymentFinder.new(@claim)
  end

  def reject_decided_claims
    if @claim.decision.present?
      redirect_to admin_claim_path(@claim), notice: "Claim outcome already decided"
    end
  end

  def reject_missing_payroll_gender
    if decision_params[:result] == "approved" && @claim.payroll_gender_missing?
      redirect_to admin_claim_path(@claim), alert: "Claim cannot be approved"
    end
  end

  def reject_if_claims_preventing_payment
    if decision_params[:result] == "approved" && claims_preventing_payment_finder.claims_preventing_payment.any?
      redirect_to admin_claim_path(@claim), alert: "Claim cannot be approved because there are inconsistent claims"
    end
  end

  def send_claim_result_email
    ClaimMailer.approved(@claim).deliver_later if @claim.decision.result == "approved"
    ClaimMailer.rejected(@claim).deliver_later if @claim.decision.result == "rejected"
  end

  def decision_params
    params.require(:decision).permit(:result, :notes)
  end
end
