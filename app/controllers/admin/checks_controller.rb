class Admin::ChecksController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim

  CHECKS_SEQUENCE = %w[qualifications employment]

  def index
  end

  def show
    @claim_checks = @claim.policy::AdminChecksPresenter.new(@claim)
    @task = @claim.tasks.find_by(name: current_check)
    render current_check
  end

  def create
    @claim.tasks.create!(name: current_check, created_by: admin_user)
    redirect_to next_check_path
  rescue ActiveRecord::RecordInvalid
    redirect_to admin_claim_check_path(@claim, check: current_check), alert: "This check has already been completed"
  end

  private

  def load_claim
    @claim = Claim.includes(:tasks).find(params[:claim_id])
  end

  def current_check
    params[:check]
  end

  def next_check
    CHECKS_SEQUENCE[CHECKS_SEQUENCE.index(current_check) + 1]
  end

  def next_check_path
    if next_check.present?
      admin_claim_check_path(@claim, check: next_check)
    else
      new_admin_claim_decision_path(@claim)
    end
  end
end
