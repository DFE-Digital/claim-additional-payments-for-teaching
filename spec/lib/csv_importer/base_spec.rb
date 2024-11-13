require "rails_helper"

RSpec.describe CsvImporter::Base do
  subject(:importer) { dummy_class.new(file) }

  let(:dummy_class) { Class.new(described_class) }
  let(:file) {
    Tempfile.new.tap { |f|
      f.write(csv_str)
      f.rewind
    }
  }
  let(:csv_str) { "" }

  let(:csv_parse_options) do
    {
      target_data_model:,
      append_only:,
      batch_size:,
      parse_headers:,
      mandatory_headers:,
      transform_rows_with:,
      skip_row_if:
    }
  end
  let(:target_data_model) { double("TargetDataModel", delete_all: nil, insert_all: nil, is_a?: true, table_name: "schools") }
  let(:append_only) { false }
  let(:batch_size) { nil }
  let(:parse_headers) { true }
  let(:mandatory_headers) { [] }
  let(:transform_rows_with) { nil }
  let(:skip_row_if) { nil }

  before { dummy_class.import_options(**csv_parse_options) }

  describe "CSV parsing and validation" do
    context "when the file is nil" do
      let(:file) { nil }

      it "sets an error message" do
        expect(importer.errors).to eq(["Select a file"])
      end
    end

    context "when the file is malformed" do
      let(:csv_str) { "\"" }

      it "sets an error message" do
        expect(importer.errors).to eq(["The selected file must be a CSV"])
      end
    end

    context "when the file is valid" do
      context "with missing headers" do
        let(:mandatory_headers) { ["a", "b", "c", "d"] }
        let(:csv_str) { "a,b\n1,2" }

        it "sets an error message" do
          expect(importer.errors).to eq(["The selected file is missing some expected columns: c, d"])
        end

        it "parses the CSV" do
          expect(importer.rows.map(&:to_h)).to eq([{"a" => "1", "b" => "2"}])
        end
      end

      context "with no missing headers" do
        let(:mandatory_headers) { ["a", "b", "c"] }
        let(:csv_str) { "a,b,c\n1,2,3" }

        it "does not set any error message" do
          expect(importer.errors).to be_empty
        end

        it "parses the CSV" do
          expect(importer.rows.map(&:to_h)).to eq([{"a" => "1", "b" => "2", "c" => "3"}])
        end
      end
    end
  end

  describe "dfe-analytics syncing" do
    it "invokes the relevant import entity job" do
      expect(AnalyticsImporter).to receive(:import).with(target_data_model)
      importer.run
    end
  end

  describe "data transformation and importing" do
    before { importer.run }

    context "with `append_only: false`" do
      let(:append_only) { false }
      let(:csv_str) { "a,b\n1,2\n3,4" }

      let(:expected_records) { [{"a" => "1", "b" => "2"}, {"a" => "3", "b" => "4"}] }

      it "issues `delete_all` on the target table and `insert_all` for the processed rows" do
        aggregate_failures do
          expect(target_data_model).to have_received(:delete_all).ordered
          expect(target_data_model).to have_received(:insert_all).with(expected_records).ordered
        end
      end
    end

    context "with `append_only: true`" do
      let(:append_only) { true }
      let(:csv_str) { "a,b\n1,2\n3,4" }

      let(:expected_records) { [{"a" => "1", "b" => "2"}, {"a" => "3", "b" => "4"}] }

      it "does not issue `delete_all` on the target table, issues `insert_all` for the processed rows" do
        aggregate_failures do
          expect(target_data_model).not_to have_received(:delete_all)
          expect(target_data_model).to have_received(:insert_all).with(expected_records).ordered
        end
      end
    end

    context "with a `skip_row_if` lambda" do
      let(:csv_str) { "a,b\n1,2\n3,NULL" }
      let(:skip_row_if) { ->(row) { row["b"] == "NULL" } }

      let(:expected_records) { [{"a" => "1", "b" => "2"}] }

      it "issues `insert_all` on the target table for the processed rows" do
        expect(target_data_model).to have_received(:insert_all).with(expected_records).ordered
      end
    end

    context "with a `transform_rows_with` lambda" do
      let(:csv_str) { "a,b\n1,2\n3,4" }
      let(:transform_rows_with) { ->(row) { {custom_key_a: row["a"] + "foo", custom_key_b: row["b"].to_i} } }

      let(:expected_records) do
        [
          {custom_key_a: "1foo", custom_key_b: 2},
          {custom_key_a: "3foo", custom_key_b: 4}
        ]
      end

      it "issues `insert_all` on the target table for the processed rows" do
        expect(target_data_model).to have_received(:insert_all).with(expected_records).ordered
      end
    end

    context "with a `batch_size` value" do
      let(:csv_str) { "a,b\n1,2\n3,4\n5,6" }
      let(:batch_size) { 2 }

      let(:expected_batch_one) { [{"a" => "1", "b" => "2"}, {"a" => "3", "b" => "4"}] }
      let(:expected_batch_two) { [{"a" => "5", "b" => "6"}] }

      it "issues `insert_all` for each batch on the target table for the processed rows" do
        aggregate_failures do
          expect(target_data_model).to have_received(:insert_all).with(expected_batch_one).ordered
          expect(target_data_model).to have_received(:insert_all).with(expected_batch_two).ordered
        end
      end
    end
  end
end
