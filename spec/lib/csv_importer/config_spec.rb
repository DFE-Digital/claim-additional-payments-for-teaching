require "rails_helper"

RSpec.describe CsvImporter::Config do
  let(:dummy_class) { Class.new { include CsvImporter::Config } }

  describe ".import_options" do
    subject(:import_options) { dummy_class.import_options(**test_config) }

    let(:test_config) do
      {
        target_data_model: double("DummyTargetModel"),
        append_only: true,
        transform_rows_with: ->(row) { row },
        skip_row_if: ->(row) { row[0] == "NULL" },
        batch_size: 1,
        parse_headers: false,
        mandatory_headers: ["x"]
      }
    end

    it "saves each configuration item as class attribute" do
      expect { import_options }
        .to change { dummy_class.append_only }.to(test_config[:append_only])
        .and change { dummy_class.transform_rows_with_lambda }.to(test_config[:transform_rows_with])
        .and change { dummy_class.skip_row_if_lambda }.to(test_config[:skip_row_if])
        .and change { dummy_class.batch_size }.to(test_config[:batch_size])
        .and change { dummy_class.parse_headers }.to(test_config[:parse_headers])
        .and change { dummy_class.mandatory_headers }.to(test_config[:mandatory_headers])
    end

    context "defaults" do
      before { import_options }

      context "when `append_only` is omitted" do
        let(:test_config) { super().except(:append_only) }

        it "sets it to false (overwrite mode)" do
          expect(dummy_class.append_only).to eq(false)
        end
      end

      context "when `transform_rows_with` is omitted" do
        let(:test_config) { super().except(:transform_rows_with) }

        it "sets the default row-to-hash transformation" do
          expect(dummy_class.transform_rows_with_lambda).to eq(described_class::DEFAULT_ROW_TRANSFORM_LAMBDA)
        end
      end

      context "when `skip_row_if` is omitted" do
        let(:test_config) { super().except(:skip_row_if) }

        it "does not set any skip row conditions" do
          expect(dummy_class.skip_row_if_lambda).to eq(nil)
        end
      end

      context "when `batch_size` is omitted" do
        let(:test_config) { super().except(:batch_size) }

        it "sets the default batch size " do
          expect(dummy_class.batch_size).to eq(described_class::DEFAULT_BATCH_SIZE)
        end
      end

      context "when `parse_headers` is omitted" do
        let(:test_config) { super().except(:parse_headers) }

        it "sets it to true " do
          expect(dummy_class.parse_headers).to eq(true)
        end
      end

      context "when `mandatory_headers` is omitted" do
        let(:test_config) { super().except(:mandatory_headers) }

        it "sets it to an empty array " do
          expect(dummy_class.mandatory_headers).to eq([])
        end
      end
    end
  end
end
