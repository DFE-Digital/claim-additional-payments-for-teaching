require "rails_helper"

RSpec.describe "admin/tasks/one_login_identity.html.erb" do
  let(:claim) do
    create(
      :claim,
      :submitted,
      policy: Policies::FurtherEducationPayments,
      onelogin_idv_at: 1.second.ago
    )
  end

  let!(:task) do
    create(
      :task,
      name: "one_login_identity",
      claim:,
      passed: false,
      reason: "no_data",
      manual: false,
      created_by: nil
    )
  end

  let(:form) do
    Admin::Tasks::GenericForm.new(name: "one_login_identity", claim:)
  end

  let(:claim_checking_tasks) do
    ClaimCheckingTasks.new(claim)
  end

  let(:admin) do
    build(:dfe_signin_user)
  end

  before do
    allow(view).to receive(:current_page?).and_return(true)

    without_partial_double_verification do
      allow(view).to receive(:current_admin).and_return(admin)
    end
  end

  it "renders correct text" do
    assign(:claim, claim)
    assign(:claim_checking_tasks, claim_checking_tasks)
    assign(:tasks_presenter, claim.policy.admin_tasks_presenter(claim))
    assign(:form, form)
    assign(:notes, [])
    assign(:task_pagination, Admin::TaskPagination.new(claim:, current_task_name: "one_login_identity"))

    render

    expect(rendered).to include("This claimant was unable to verify their identity with")
  end
end
