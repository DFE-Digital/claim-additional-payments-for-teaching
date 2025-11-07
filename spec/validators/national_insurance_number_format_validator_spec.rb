require "rails_helper"

RSpec.describe NationalInsuranceNumberFormatValidator do
  let(:klass) do
    Class.new do
      include ActiveModel::Model

      def self.model_name
        ActiveModel::Name.new(self, nil, "Claim")
      end

      attr_accessor :nino

      validates :nino,
        national_insurance_number_format: {
          message: "NI error goes here"
        }
    end
  end

  subject { klass.new(nino:) }

  # source from:
  # https://www.gov.uk/hmrc-internal-manuals/national-insurance-manual/nim39110

  context "valid values" do
    it "passes validation" do
      expect(klass.new(nino: "AA123456A")).to be_valid
    end
  end

  context "The characters D, F, I, Q, U, and V are not used as either the first or second letter of a NINO prefix" do
    let(:valid_mask) { "AA123456A" }
    let(:unpermitted_values) { %w[D F I Q U V] }

    it "fails first letter validation" do
      unpermitted_values.each do |letter|
        value = valid_mask.dup
        value[0] = letter
        expect(klass.new(nino: value)).to be_invalid
      end
    end

    it "fails second letter validation" do
      unpermitted_values.each do |letter|
        value = valid_mask.dup
        value[1] = letter
        expect(klass.new(nino: value)).to be_invalid
      end
    end
  end

  context "The letter O is not used as the second letter of a prefix" do
    let(:valid_mask) { "AA123456A" }
    let(:unpermitted_values) { %w[O] }

    it "fails second letter validation" do
      unpermitted_values.each do |letter|
        value = valid_mask.dup
        value[1] = letter
        expect(klass.new(nino: value)).to be_invalid
      end
    end
  end

  context "Prefixes BG, GB, KN, NK, NT, TN and ZZ are not to be used" do
    let(:valid_mask) { "AA123456A" }
    let(:unpermitted_prefixes) { %w[BG GB KN NK NT TN ZZ] }

    it "fails prefix validation" do
      unpermitted_prefixes.each do |prefix|
        value = valid_mask.dup
        value[0..1] = prefix
        expect(klass.new(nino: value)).to be_invalid
      end
    end
  end

  context "Final letter, which is always A, B, C, or D" do
    let(:valid_mask) { "AA123456A" }
    let(:permitted_characters) { %w[A B C D] }
    let(:unpermitted_characters) { ("A".."Z").to_a - permitted_characters }

    it "passes suffix validation" do
      permitted_characters.each do |suffix|
        value = valid_mask.dup
        value[8] = suffix
        expect(klass.new(nino: value)).to be_valid
      end
    end

    it "fails suffix validation" do
      unpermitted_characters.each do |suffix|
        value = valid_mask.dup
        value[8] = suffix
        expect(klass.new(nino: value)).to be_invalid
      end
    end
  end

  context "when multiple validation issues" do
    subject { klass.new(nino: "DD123456A") }

    it "prevents cumulative errors" do
      expect(subject).to be_invalid
      expect(subject.errors.size).to eql(1)
    end
  end
end
