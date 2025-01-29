require "rails_helper"

class TestRecord
  include ActiveModel::Validations

  attr_accessor :email

  validates :email, email_address_format: {message: "no good"}
end

RSpec.describe EmailAddressFormatValidator do
  context "with an invalid email address" do
    [
      "noatsign.domain",
      "@nolocal.com",
      "contains space@example.com",
      "too@many@signs.com",
      "double..dot@example.com",
      "doubledot-in-domain@sub..domain.com",
      "tldonly@com",
      "trailingdot@subdomain.",
      "test@-badlabel.co",
      "test@bad_domain.com",
      "toolong-dmain@#{"a" * 64}.com",
      "bad-tld@example.c",
      "bad-tld@example.com1"
    ].each do |string|
      it "rejects #{string}" do
        record = TestRecord.new
        record.email = string

        expect(record.valid?).to be false

        expect(record.errors[:email]).to include("no good")
      end
    end
  end

  context "with a valid email address" do
    [
      "test@example.com",
      "first.o'surname+123@sub.domain.co.uk",
      "abc@my-long-subdomain.gov.uk",
      "someone@domain.org"
    ].each do |string|
      it "accepts #{string}" do
        record = TestRecord.new
        record.email = string

        expect(record.valid?).to be true

        expect(record.errors[:email]).to be_empty
      end
    end
  end
end
