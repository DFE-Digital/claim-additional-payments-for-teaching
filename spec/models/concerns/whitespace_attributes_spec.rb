require "rails_helper"

RSpec.describe WhitespaceAttributes do
  let(:dummy_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks
      include WhitespaceAttributes

      attribute :email, :string
      attribute :ni, :string, strip_all_whitespace: true
      attribute :keep_space, :string, keep_whitespace: true
    end
  end

  subject do
    dummy_class.new(
      email: " bob@example.com ",
      ni: " AB 12 34 56 C ",
      keep_space: " A B C "
    )
  end

  it "strips whitespace accordingly" do
    subject.valid?

    expect(subject.email).to eql("bob@example.com")
    expect(subject.ni).to eql("AB123456C")
    expect(subject.keep_space).to eql(" A B C ")
  end
end
