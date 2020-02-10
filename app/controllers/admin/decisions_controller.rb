class Admin::DecisionsController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim
  before_action :reject_checked_claims
  before_action :reject_missing_payroll_gender
  before_action :reject_if_claims_preventing_payment

  def create
    @check = @claim.build_check(decision_params.merge(checked_by: admin_user))
    if @check.save
      send_claim_result_email
      RecordOrUpdateGeckoboardDatasetJob.perform_later([@claim.id])
      redirect_to admin_claims_path, notice: "Claim has been #{@claim.check.result} successfully"
    else
      @claims_preventing_payment = claims_preventing_payment_finder.claims_preventing_payment
      render "admin/claims/show"
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

  def reject_checked_claims
    if @claim.check.present?
      redirect_to admin_claim_path(@claim), notice: "Claim already checked"
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
    ClaimMailer.approved(@claim).deliver_later if @claim.check.result == "approved"
    ClaimMailer.rejected(@claim).deliver_later if @claim.check.result == "rejected"
  end

  def decision_params
    params.require(:check).permit(:result, :notes)
  end
end
