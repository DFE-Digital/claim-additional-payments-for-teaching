require "rails_helper"

RSpec.describe Answer do
  subject(:answer) do
    described_class.new(value:, label:, hint:, field_name:)
  end

  let(:value) { "value" }
  let(:label) { "some label" }
  let(:hint) { "hint" }
  let(:field_name) { :field }

  context "formats Date value" do
    let(:value) { Date.new(2023, 1, 1) }

    it { expect(answer.formatted_value).to eq("01-01-2023") }
  end

  it { expect(answer.value).to eq(value) }
  it { expect(answer.formatted_value).to eq(value) }
  it { expect(answer.label).to eq(label) }
  it { expect(answer.hint).to eq(hint) }
  it { expect(answer.field_name).to eq(field_name) }
end
