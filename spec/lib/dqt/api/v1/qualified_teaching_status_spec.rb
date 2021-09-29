require "rails_helper"

module Dqt
  class Api
    class V1
      describe QualifiedTeachingStatus do
        subject(:qualified_teaching_status) { described_class.new(response: qualified_teaching_status_response) }

        let(:qualified_teaching_status_response) do
          {
            id: 28,
            trn: "1775670",
            name: "Fenton Laing",
            doB: "1987-08-22T00:00:00",
            niNumber: "JR501209A",
            qtsAwardDate: "2020-04-03T00:00:00",
            ittSubject1Code: "G100",
            ittSubject2Code: "NULL",
            ittSubject3Code: "NULL",
            activeAlert: false,
            qualificationName: "Graduate Diploma",
            ittStartDate: "2019-04-04T00:00:00",
            teacherStatus: nil
          }
        end

        shared_examples "integer reader" do |response_key|
          context "when response value Integer" do
            before { qualified_teaching_status_response[response_key] = 1 }

            it "returns Integer" do
              expect(subject).to equal 1
            end
          end

          context "when response value Integer as String" do
            before { qualified_teaching_status_response[response_key] = "2" }

            it "returns Integer" do
              expect(subject).to equal 2
            end
          end

          context "when response value non Integer String" do
            before { qualified_teaching_status_response[response_key] = "x" }

            it "reports error to Rollbar" do
              allow(Rollbar).to receive(:error)

              subject

              expect(Rollbar).to have_received(:error)
            end

            it "returns nil" do
              expect(subject).to equal nil
            end
          end

          context "when response value nil" do
            before { qualified_teaching_status_response[response_key] = nil }

            it "returns nil" do
              expect(subject).to equal nil
            end
          end

          [
            "nil",
            "NIL",
            "Nil",
            "NiL",
            " nil ",
            "null",
            "NULL",
            "Null",
            "NuLl",
            " null "
          ].each do |nil_string|
            context "when response value nil (eg '#{nil_string}') as String" do
              before { qualified_teaching_status_response[response_key] = nil_string }

              it "returns nil" do
                expect(subject).to equal nil
              end
            end
          end
        end

        shared_examples "string reader" do |response_keys|
          let(:collection) { response_keys.respond_to?(:each) }
          let(:response_keys) { response_keys }

          def expectation(expectation)
            collection ? Array.new(response_keys.length, expectation).compact : expectation
          end

          def response(response)
            response_func = ->(response_key) { qualified_teaching_status_response[response_key] = response }

            if collection
              response_keys.each do |response_key|
                response_func.call(response_key)
              end
            else
              response_func.call(response_keys)
            end
          end

          context "when response values String" do
            before { response("AString") }

            it "returns String" do
              expect(subject).to eql expectation("AString")
            end
          end

          context "when response value String as Integer" do
            before { response(12345) }

            it "returns String" do
              expect(subject).to eql expectation("12345")
            end
          end

          context "when response value nil" do
            before { response(nil) }

            it "returns nil" do
              expect(subject).to eql expectation(nil)
            end
          end

          [
            "nil",
            "NIL",
            "Nil",
            "NiL",
            " nil ",
            "null",
            "NULL",
            "Null",
            "NuLl",
            " null "
          ].each do |nil_string|
            context "when response value nil (eg '#{nil_string}') as String" do
              before { response(nil_string) }

              it "returns nil" do
                expect(subject).to eql expectation(nil)
              end
            end
          end
        end

        shared_examples "date reader" do |response_key|
          context "when response value Date as String" do
            before { qualified_teaching_status_response[response_key] = "1944-10-22" }

            it "returns String" do
              expect(subject).to eq Date.new(1944, 10, 22)
            end
          end

          [
            "1944-10-22T00:00:00",
            "1944-10-22T00:00:00+00:00",
            "1944-10-22T00:00:00.1440844Z",
            "1944-10-22T00:00:00.1440844-00:00"
          ].each do |date_time|
            context "when response value DateTime as String (eg '#{date_time}')" do
              before { qualified_teaching_status_response[response_key] = date_time }

              it "returns Date" do
                expect(subject).to eq Date.new(1944, 10, 22)
              end
            end
          end

          context "when response value Time as Integer" do
            before { qualified_teaching_status_response[response_key] = -795052800 }

            it "returns Date" do
              expect(subject).to eq Date.new(1944, 10, 22)
            end
          end

          context "when response value Time as String" do
            before { qualified_teaching_status_response[response_key] = "-795052800" }

            it "returns Date" do
              expect(subject).to eq Date.new(1944, 10, 22)
            end
          end

          context "when response value non Date as String" do
            before { qualified_teaching_status_response[response_key] = "x" }

            it "reports error to Rollbar" do
              allow(Rollbar).to receive(:error)

              subject

              expect(Rollbar).to have_received(:error)
            end

            it "returns nil" do
              expect(subject).to equal nil
            end
          end

          context "when response value nil" do
            before { qualified_teaching_status_response[response_key] = nil }

            it "returns nil" do
              expect(subject).to equal nil
            end
          end

          [
            "nil",
            "NIL",
            "Nil",
            "NiL",
            " nil ",
            "null",
            "NULL",
            "Null",
            "NuLl",
            " null "
          ].each do |nil_string|
            context "when response value nil (eg '#{nil_string}') as String" do
              before { qualified_teaching_status_response[response_key] = nil_string }

              it "returns nil" do
                expect(subject).to equal nil
              end
            end
          end
        end

        shared_examples "boolean reader" do |response_key|
          context "when response value true" do
            before { qualified_teaching_status_response[response_key] = true }

            it "returns true" do
              expect(subject).to equal true
            end
          end

          context "when response value false" do
            before { qualified_teaching_status_response[response_key] = false }

            it "returns false" do
              expect(subject).to equal false
            end
          end

          [
            "true",
            "TRUE",
            "True",
            "TrUe",
            " true "
          ].each do |true_string|
            context "when response value true as String (eg '#{true_string}')" do
              before { qualified_teaching_status_response[response_key] = true_string }

              it "returns true" do
                expect(subject).to equal true
              end
            end
          end

          [
            "false",
            "FALSE",
            "False",
            "FaLsE",
            " false "
          ].each do |false_string|
            context "when response value false as String (eg '#{false_string}')" do
              before { qualified_teaching_status_response[response_key] = false_string }

              it "returns false" do
                expect(subject).to equal false
              end
            end
          end

          context "when response value nil" do
            before { qualified_teaching_status_response[response_key] = nil }

            it "returns nil" do
              expect(subject).to equal nil
            end
          end

          [
            "nil",
            "NIL",
            "Nil",
            "NiL",
            " nil ",
            "null",
            "NULL",
            "Null",
            "NuLl",
            " null "
          ].each do |nil_string|
            context "when response value nil (eg '#{nil_string}') as String" do
              before { qualified_teaching_status_response[response_key] = nil_string }

              it "returns nil" do
                expect(subject).to equal nil
              end
            end
          end
        end

        describe "#id" do
          subject(:id) { qualified_teaching_status.id }

          it_behaves_like "integer reader", :id
        end

        describe "#teacher_reference_number" do
          subject(:teacher_reference_number) { qualified_teaching_status.teacher_reference_number }

          it_behaves_like "string reader", :trn
        end

        describe "#first_name" do
          subject(:first_name) { qualified_teaching_status.first_name }

          it_behaves_like "string reader", :name

          [
            {name: "Fenton Laing", first_name: "Fenton"},
            {name: "Fenton La La Laing", first_name: "Fenton"},
            {name: " Fenton La Laing ", first_name: "Fenton"},
            {name: "fenton laing", first_name: "fenton"}
          ].each do |scenario|
            context "when response name '#{scenario[:name]}' String" do
              before { qualified_teaching_status_response[:name] = scenario[:name] }

              it "returns '#{scenario[:first_name]}'" do
                expect(first_name).to eq scenario[:first_name]
              end
            end
          end
        end

        describe "#surname" do
          subject(:surname) { qualified_teaching_status.surname }

          it_behaves_like "string reader", :name

          [
            {name: "Fenton Laing", surname: "Laing"},
            {name: "Fenton La La Laing", surname: "Laing"},
            {name: " Fenton La Laing ", surname: "Laing"},
            {name: "fenton laing", surname: "laing"}
          ].each do |scenario|
            context "when response name String (eg '#{scenario[:name]}')" do
              before { qualified_teaching_status_response[:name] = scenario[:name] }

              it "returns '#{scenario[:surname]}'" do
                expect(surname).to eq scenario[:surname]
              end
            end
          end
        end

        describe "#date_of_birth" do
          subject(:date_of_birth) { qualified_teaching_status.date_of_birth }

          it_behaves_like "date reader", :doB
        end

        describe "#degree_codes" do
          subject(:degree_codes) { qualified_teaching_status.degree_codes }

          it "returns Array" do
            expect(degree_codes).to eq []
          end
        end

        describe "#national_insurance_number" do
          subject(:national_insurance_number) { qualified_teaching_status.national_insurance_number }

          it_behaves_like "string reader", :niNumber
        end

        describe "#qts_award_date" do
          subject(:qts_award_date) { qualified_teaching_status.qts_award_date }

          it_behaves_like "date reader", :qtsAwardDate
        end

        describe "#itt_subject_codes" do
          subject(:itt_subject_codes) { qualified_teaching_status.itt_subject_codes }

          it_behaves_like(
            "string reader",
            (1..3).map { |n| "ittSubject#{n}Code".to_sym }
          )
        end

        describe "#active_alert?" do
          subject(:active_alert?) { qualified_teaching_status.active_alert? }

          it_behaves_like "boolean reader", :activeAlert
        end

        describe "#qualification_name" do
          subject(:qualification_name) { qualified_teaching_status.qualification_name }

          it_behaves_like "string reader", :qualificationName
        end

        describe "#itt_start_date" do
          subject(:itt_start_date) { qualified_teaching_status.itt_start_date }

          it_behaves_like "date reader", :ittStartDate
        end
      end
    end
  end
end
