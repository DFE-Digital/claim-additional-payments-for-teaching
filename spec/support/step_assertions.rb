RSpec.shared_examples "behaves like a step" do |klass, args|
  I18n.with_locale("en") do
    describe "validation" do
      described_class::REQUIRED_FIELDS.each do |field|
        it "validates presence of #{field}" do
          expect(step).to validate_presence_of(field)
        end
      end

      if args[:optional_fields]
        described_class::OPTIONAL_FIELDS.each do |field|
          it "does not validate presence of #{field}" do
            expect(step).not_to validate_presence_of(field)
          end
        end
      end

      if %i[radio select].include?(args[:question_type])
        field = described_class::REQUIRED_FIELDS.first

        it "validates #{field} allowed values" do
          expect(step).to validate_inclusion_of(field).in_array(described_class::VALID_ANSWERS_OPTIONS)
        end
      end
    end

    it "has a question" do
      expect(step.question).to eq(args[:question])
    end

    it "has a question_type" do
      expect(step.question_type).to eq(args[:question_type])
    end

    if args[:question_hint]
      it "has a question hint" do
        expect(step.question_hint).to eq(args[:question_hint])
      end
    end

    if args[:valid_answers]
      it "has valid answers" do
        valid_answers_label = step.valid_answers.map(&:label)
        expect(valid_answers_label).to match_array(args[:valid_answers])
      end
    end

    it "has a route key" do
      expect(klass::ROUTE_KEY).to eq(args[:route_key])
    end

    it "has required fields" do
      expect(klass::REQUIRED_FIELDS).to eq(args[:required_fields])
    end

    if args[:optional_fields]
      it "has optional fieldls" do
        expect(klass::OPTIONAL_FIELDS).to eq(args[:optional_fields])
      end
    end

    it "uses template" do
      template = args[:template] || "step/base_step"
      expect(step.template).to eq(template)
    end

    it "has a path" do
      expect(step).to respond_to(:path)
    end
  end
end
