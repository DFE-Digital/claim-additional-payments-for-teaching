RSpec.shared_examples "stub_teacher_auth" do
  let(:mock_teacher) do
    instance_double(
      "Dqt::Teacher",
      has_eligible_eytfi_qualification?: true
    )
  end

  let(:mock_teacher_resource) do
    instance_double(
      "Dqt::TeacherResource",
      find: mock_teacher
    )
  end

  let(:mock_client) do
    instance_double(
      "Dqt::Client",
      teacher: mock_teacher_resource
    )
  end

  before do
    allow(Dqt::Client).to receive(:new).and_return(mock_client)
  end
end

RSpec.shared_examples "stub_teacher_auth_with_ineligible_qualification" do
  let(:mock_teacher) do
    instance_double(
      "Dqt::Teacher",
      has_eligible_eytfi_qualification?: false
    )
  end

  let(:mock_teacher_resource) do
    instance_double(
      "Dqt::TeacherResource",
      find: mock_teacher
    )
  end

  let(:mock_client) do
    instance_double(
      "Dqt::Client",
      teacher: mock_teacher_resource
    )
  end

  before do
    allow(Dqt::Client).to receive(:new).and_return(mock_client)
  end
end
