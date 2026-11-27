require "rails_helper"

RSpec.describe EarlyYearsTeachersFinancialIncentivePayments::ImportEligibleEytfiProvidersJob do
  let(:file_upload) do
    create(
      :file_upload,
      :with_current_academic_year,
      :not_completed_processing,
      target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider,
      body: file_fixture("eligible_eytfi_providers.csv").read
    )
  end

  it "persists registered person details and leaves optional fields nil" do
    upload = create(
      :file_upload,
      :with_current_academic_year,
      :not_completed_processing,
      target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider,
      body: file_fixture("eligible_eytfi_providers.csv").read
    )

    described_class.new.perform(upload)

    providers = Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider

    expect(providers.find_by!(urn: "123456")).to have_attributes(
      registered_person_name: "example ltd",
      telephone_number: "01234567890",
      paye_references: ["123/AB456"],
      multiple_nurseries: true
    )

    expect(providers.find_by!(urn: "EY234567")).to have_attributes(
      registered_person_name: nil,
      telephone_number: nil,
      paye_references: [],
      multiple_nurseries: nil
    )
  end

  describe "#perform" do
    ["\n", "\r\n"].each do |newline|
      it "imports newline-separated PAYE references using #{newline.inspect}" do
        rows = CSV.parse(file_upload.body, headers: true)
        rows.first["PAYE reference"] = ["475HB32613", "9612701970"].join(newline)
        file_upload.update!(body: rows.to_csv)

        subject.perform(file_upload)

        provider = Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.find_by!(urn: "123456")
        expect(provider.paye_references).to eq(["475HB32613", "9612701970"])
        expect(file_upload.reload.completed_processing_at).to be_present
      end
    end

    it "imports n/a PAYE references as blank" do
      file_upload.update!(body: file_upload.body.sub("123/AB456", "n/a"))

      subject.perform(file_upload)

      provider = Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.find_by!(urn: "123456")
      expect(provider.paye_references).to eq([])
      expect(file_upload.reload.completed_processing_at).to be_present
    end

    it "creates eytfi provider" do
      expect {
        subject.perform(file_upload)
      }.to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count).by(2)
    end

    it "touches file upload completed_processing_at" do
      subject.perform(file_upload)

      expect(file_upload.reload.completed_processing_at).to be_present
    end

    context "when columns are in a different order" do
      before do
        rows = CSV.parse(file_upload.body)
        file_upload.update!(body: CSV.generate { |csv| rows.each { |row| csv << row.reverse } })
      end

      it "imports providers with values matched to their column names" do
        expect {
          subject.perform(file_upload)
        }.to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count).by(2)

        provider = Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.find_by!(urn: "123456")
        expect(provider).to have_attributes(
          name: "Nursery 123456",
          address_line_1: "1 Some Road",
          town: "London",
          postcode: "EC1N 2TD",
          eligible: true,
          max_claims: 5,
          copd: false,
          registered_person_name: "example ltd",
          telephone_number: "01234567890",
          paye_references: ["123/AB456"],
          multiple_nurseries: true
        )
        expect(file_upload.reload.upload_errors).to be_blank
        expect(file_upload.completed_processing_at).to be_present
      end
    end

    described_class::RowParser::HEADERS.each do |header|
      context "when the #{header} column is missing" do
        before do
          rows = CSV.parse(file_upload.body)
          column_index = rows.first.index(header)
          rows.each { |row| row.delete_at(column_index) }
          file_upload.update!(body: CSV.generate { |csv| rows.each { |row| csv << row } })
        end

        it "rejects the upload" do
          expect {
            subject.perform(file_upload)
          }.not_to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)

          expect(file_upload.reload.upload_errors).to eq([
            "Headers must be #{described_class::RowParser::HEADERS.join(", ")}"
          ])
          expect(file_upload.completed_processing_at).to be_nil
        end
      end
    end

    context "job runs twice" do
      it "does not duplicate records" do
        expect {
          subject.perform(file_upload)
        }.to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)

        expect {
          subject.perform(file_upload)
        }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context "when uploads twice" do
      let(:second_file_upload) do
        create(
          :file_upload,
          :with_current_academic_year,
          :not_completed_processing,
          target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider,
          body: file_fixture("eligible_eytfi_providers.csv").read
        )
      end

      it "appends records" do
        expect {
          subject.perform(file_upload)
        }.to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)

        expect {
          subject.perform(second_file_upload)
        }.to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)
      end
    end

    context "when there is a validation error" do
      let(:file_upload) do
        create(
          :file_upload,
          :with_current_academic_year,
          :not_completed_processing,
          target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider,
          body: file_fixture("eligible_eytfi_providers_with_error.csv").read
        )
      end

      it "does not create any records" do
        expect {
          subject.perform(file_upload)
        }.not_to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)
      end

      it "saves errors on file upload" do
        subject.perform(file_upload)

        expect(file_upload.reload.upload_errors).to eql(["Row 4: Eligible must be TRUE or FALSE"])
      end
    end

    context "when incorrect headers" do
      let(:file_upload) do
        create(
          :file_upload,
          :with_current_academic_year,
          :not_completed_processing,
          target_data_model: Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider,
          body: "wrong,headers,here"
        )
      end

      it "does not create any records" do
        expect {
          subject.perform(file_upload)
        }.not_to change(Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider, :count)
      end

      it "saves errors on file upload" do
        subject.perform(file_upload)

        expect(file_upload.reload.upload_errors).to eql(["Headers must be Provider name, Provider address line 1, Provider address line 2, Provider address line 3, Provider town, Postcode, Provider URN, Eligible, Max claims, COPD, Registered person name, Telephone number, PAYE reference, Multiple nurseries?"])
      end
    end
  end
end

RSpec.describe EarlyYearsTeachersFinancialIncentivePayments::ImportEligibleEytfiProvidersJob::RowParser, type: :model do
  let(:file_upload) do
    create(:file_upload)
  end

  subject { described_class.new(row:) }

  describe "n/a values" do
    let(:row) do
      CSV.parse(
        file_fixture("eligible_eytfi_providers.csv").read,
        headers: true
      ).first
    end

    it "ignores blank and n/a lines and trims PAYE references" do
      row["PAYE reference"] = " 475HB32613 \r\n\r\n n/a \r\n9612701970\n"

      expect(subject.to_provider(file_upload: build(:file_upload)).paye_references).to eq([
        "475HB32613", "9612701970"
      ])
    end

    [
      "Provider URN",
      "Provider name",
      "Provider address line 1",
      "Provider town",
      "Postcode",
      "Eligible"
    ].each do |header|
      it "rejects n/a in the required #{header} field" do
        row[header] = "n/a"

        expect(subject).not_to be_valid

        expect(subject.errors[header]).to include("can't be blank")
      end
    end

    it "treats optional n/a values as blank, including defaults and conditional validations" do
      [
        "Provider address line 2",
        "Provider address line 3",
        "Max claims",
        "COPD",
        "Registered person name",
        "Telephone number",
        "PAYE reference",
        "Multiple nurseries?"
      ].each do |header|
        row[header] = "n/a"
      end

      expect(subject).to be_valid

      expect(
        subject.to_provider(file_upload: build(:file_upload))
      ).to have_attributes(
        address_line_2: nil,
        address_line_3: nil,
        max_claims: 5,
        copd: false,
        registered_person_name: nil,
        telephone_number: nil,
        paye_references: [],
        multiple_nurseries: nil
      )
    end

    it "requires a boolean when the multiple nurseries field is n/a and a registered person is present" do
      row["Multiple nurseries?"] = "n/a"

      expect(subject).not_to be_valid
      expect(
        subject.errors["Multiple nurseries?"]
      ).to include("must be TRUE or FALSE")
    end
  end

  describe "registered person details" do
    it "accepts false when a registered person is present" do
      row = CSV.parse(
        file_fixture("eligible_eytfi_providers.csv").read,
        headers: true
      ).first

      row["Multiple nurseries?"] = "FALSE"

      parser = described_class.new(row: row)

      expect(parser).to be_valid
      expect(
        parser.to_provider(file_upload: build(:file_upload)).multiple_nurseries
      ).to be false
    end

    it "requires a boolean when a registered person is present" do
      row = CSV.parse(
        file_fixture("eligible_eytfi_providers.csv").read,
        headers: true
      ).first

      row["Multiple nurseries?"] = nil

      parser = described_class.new(row: row)

      expect(parser).not_to be_valid

      expect(parser.errors["Multiple nurseries?"]).to include(
        "must be TRUE or FALSE"
      )
    end

    it "rejects invalid booleans when a registered person is present" do
      row = CSV.parse(
        file_fixture("eligible_eytfi_providers.csv").read,
        headers: true
      ).first

      row["Multiple nurseries?"] = "yes"

      parser = described_class.new(row: row)

      expect(parser).not_to be_valid

      expect(parser.errors["Multiple nurseries?"]).to include(
        "must be TRUE or FALSE"
      )
    end

    it "requires the flag to be absent when no registered person is present" do
      row = CSV.parse(
        file_fixture("eligible_eytfi_providers.csv").read,
        headers: true
      ).first

      row["Registered person name"] = nil

      parser = described_class.new(row: row)

      expect(parser).not_to be_valid

      expect(parser.errors["Multiple nurseries?"]).to include("must be blank")
    end
  end

  describe "#validations" do
    context "urn" do
      context "when urn missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider URN"]).to be_present
        end
      end

      context "when urn too short" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "12345"
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider URN"]).to be_present
        end
      end

      context "when urn too long" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "123456789"
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider URN"]).to be_present
        end
      end
    end

    context "name" do
      context "name missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider name"]).to be_present
        end
      end
    end

    context "adress line 1" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider address line 1"]).to be_present
        end
      end
    end

    context "town" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Provider town"]).to be_present
        end
      end
    end

    context "postcode" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Postcode"]).to be_present
        end
      end
    end

    context "eligible" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              ""
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Eligible"]).to be_present
        end
      end

      context "when COPD is true" do
        context "with missing URN, address and postcode" do
          let(:row) do
            CSV::Row.new(
              described_class::HEADERS,
              [
                "Some nursery",
                "",
                "",
                "",
                "Some Town",
                "",
                "",
                "TRUE",
                "5",
                "TRUE"
              ],
              true
            )
          end

          it "skips URN, address and postcode validation" do
            expect(subject).to be_valid
          end
        end
      end

      context "is malformatted" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "foo"
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Eligible"]).to be_present
        end
      end
    end

    context "copd" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "123456",
              "Some nursery",
              "Some Road",
              "Somewhere",
              "Somewhere Else",
              "Some Town",
              "TE57 1NG",
              "TRUE",
              "5",
              ""
            ],
            true
          )
        end

        it "defaults to false" do
          provider = subject.to_provider(file_upload:)
          expect(provider.copd).to be false
        end
      end
    end

    context "max claims" do
      context "is missing" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "123456",
              "Some nursery",
              "Some Road",
              "Somewhere",
              "Somewhere Else",
              "Some Town",
              "TE57 1NG",
              "TRUE",
              ""
            ],
            true
          )
        end

        it "defaults to 5" do
          provider = subject.to_provider(file_upload:)
          expect(provider.max_claims).to eql(5)
        end
      end

      context "is not a positive integer" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "-1"
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Max claims"]).to be_present
        end
      end

      context "is not an integer" do
        let(:row) do
          CSV::Row.new(
            described_class::HEADERS,
            [
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "",
              "foo"
            ],
            true
          )
        end

        it "is not valid" do
          subject.valid?
          expect(subject.errors["Max claims"]).to be_present
        end
      end
    end
  end

  describe "#to_provider" do
    let(:row) do
      CSV::Row.new(
        described_class::HEADERS,
        [
          "Some nursery",
          "Some Road",
          "Somewhere",
          "Somewhere Else",
          "London",
          "EC1N 2TD",
          "EY123456",
          "TRUE",
          "5",
          "FALSE"
        ],
        true
      )
    end

    it "returns provider object" do
      expected = Policies::
        EarlyYearsTeachersFinancialIncentivePayments::
        EligibleEytfiProvider.new(
          urn: "EY123456",
          name: "Some nursery",
          address_line_1: "Some Road",
          address_line_2: "Somewhere",
          address_line_3: "Somewhere Else",
          town: "London",
          postcode: "EC1N 2TD",
          eligible: true,
          max_claims: 5,
          copd: false,
          file_upload:
        )

      expect(subject.to_provider(file_upload:).attributes).to eql(expected.attributes)
    end
  end

  describe "PAYE references in public fields" do
    let(:row) do
      CSV.parse(
        file_fixture("eligible_eytfi_providers.csv").read,
        headers: true
      ).first
    end

    let(:message) do
      "looks like it contains a PAYE reference, PAYE references must " \
        "only be in the PAYE reference column"
    end

    described_class::PUBLIC_HEADERS.each do |header|
      [
        "120HB54729",
        "120/HB54729",
        "120hb54729",
        "267K148",
        "783HP64",
        "123A4",
        "951P877WW",
        "120GE37438 Nursery",
        "Nursery (120GE37438)",
        "9612701970",
        "12345678",
        "120HB547291",
        "123ABC456789XYZ"
      ].each do |value|
        it "rejects #{value.inspect} in #{header}" do
          row[header] = value

          expect(subject).not_to be_valid
          expect(subject.errors[header]).to eq([message])
        end
      end

      it "rejects the row's own PAYE reference in #{header}" do
        row["PAYE reference"] = "AB/1234\n120HB54729"
        row[header] = "Nursery ab1234"

        expect(subject).not_to be_valid
        expect(subject.errors[header]).to eq([message])
      end
    end

    [
      "SW1A 1AA",
      "EC1A 1BB",
      "W1A 0AX",
      "M1 1AE",
      "B33 8TH",
      "CR2 6XH",
      "DN55 1PT",
      "1212a Warwick Road",
      "Unit 2117a",
      "227th Scouts",
      "Flat 12B, 123 High Street",
      "Little Stars Nursery",
      "PO Box 1234"
    ].each do |value|
      it "accepts #{value.inspect}" do
        described_class::PUBLIC_HEADERS.each do |header|
          row[header] = value
        end

        subject.valid?

        described_class::PUBLIC_HEADERS.each do |header|
          expect(subject.errors[header]).to be_empty
        end
      end
    end

    it "does not include the PAYE reference in the error" do
      row["Provider name"] = "120HB54729"

      subject.valid?

      expect(subject.errors.full_messages.join).not_to include("120HB54729")
    end
  end
end
