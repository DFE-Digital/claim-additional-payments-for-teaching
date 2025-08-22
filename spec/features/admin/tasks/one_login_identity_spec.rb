require "rails_helper"

RSpec.feature "Admin performs one login identity task" do
  let(:claim) do
    create(
      :claim,
      :submitted,
      :with_onelogin_idv_data,
      policy: Policies::FurtherEducationPayments,
      onelogin_idv_return_codes: ["A", "B"],
      tasks:
    )
  end

  let(:tasks) do
    [
      create(
        :task,
        name: "one_login_identity",
        passed: false,
        reason: "no_data",
        manual: false,
        created_by: nil
      )
    ]
  end
end
