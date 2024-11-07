RSpec.shared_context "with DfE Analytics enabled", shared_context: :metadata do
  before { allow(DfE::Analytics).to receive(:enabled?).and_return(true) }
  after { allow(DfE::Analytics).to receive(:enabled?).and_return(false) }
end

RSpec.configure do |rspec|
  rspec.include_context "with DfE Analytics enabled", with_dfe_analytics_enabled: true
end
