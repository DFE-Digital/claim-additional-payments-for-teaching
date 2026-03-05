require "csv"

module Policies
  module TargetedRetentionIncentivePayments
    module Test
      # The purpose of this class to fetch data from TRS
      # then update CSV fixtures with snapshot of that data
      class TrsImporter
        def call
          guard_production
          guard_credentials_missing

          personas.each do |persona|
            teacher = client.teacher.find persona.teacher_reference_number

            if teacher.nil?
              raise "No teacher with TRN: #{persona.teacher_reference_number} found in TRS"
            end

            persona.trs_first_name = teacher.first_name
            persona.trs_last_name = teacher.surname
            persona.trs_date_of_birth = teacher.date_of_birth
            persona.trs_national_insurance_number = teacher.national_insurance_number
            persona.trs_email_address = teacher.email_address
            persona.trs_induction_start_date = teacher.induction_start_date
            persona.trs_induction_completion_date = teacher.induction_completion_date
            persona.trs_induction_status = teacher.induction_status
            persona.trs_induction_start_date = teacher.induction_start_date
            persona.trs_qts_award_date = teacher.qts_award_date
            persona.trs_itt_subject_codes = teacher.itt_subject_codes
            persona.trs_itt_subjects = teacher.itt_subjects
            persona.trs_itt_start_date = teacher.itt_start_date
            persona.trs_qualification_name = teacher.qualification_name
            persona.trs_degree_codes = teacher.degree_codes
            persona.trs_degree_names = teacher.degree_names
            persona.trs_active_alert = teacher.active_alert?
          end

          CSV.open(UserPersona::FILE, "w") do |csv|
            csv << UserPersona::HEADERS

            personas.each do |persona|
              csv << persona.to_csv_row
            end
          end
        end

        private

        def personas
          @personas ||= UserPersona.all
        end

        def client
          @client ||= Dqt::Client.new
        end

        def guard_production
          raise "Cannot run in production" if Rails.env.production?
        end

        def guard_credentials_missing
          if ENV["DQT_API_URL"].blank? || ENV["DQT_API_KEY"].blank? || ENV["DQT_BASE_URL"].blank?
            raise "TRS credentials not found"
          end
        end
      end
    end
  end
end
