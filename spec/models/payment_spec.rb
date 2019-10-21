require "rails_helper"

RSpec.describe Payment do
  subject { build(:payment) }

  it "has the right associations" do
    expect(subject.claim).to be_a(Claim)
    expect(subject.payroll_run).to be_a(PayrollRun)
  end
end
