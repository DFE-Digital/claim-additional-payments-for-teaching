module TestSeeders
  module Eligibilities
    module StudentLoans
      class Importer
        include StudentLoans

        ELIGIBILITY_COLUMNS = [
          :qts_award_year,
          :current_school_id,
          :claim_school_id,
          :employment_status,
          :taught_eligible_subjects,
          :biology_taught,
          :chemistry_taught,
          :physics_taught,
          :computing_taught,
          :languages_taught,
          # :student_loan_repayment_amount,
          :had_leadership_position,
          :created_at,
          :updated_at
        ].freeze

        def initialize(records)
          @records = records
          @logger = Logger.new($stdout)
        end

        def run
          @school_id ||= schools_id
          logger.info "Seeding #{records.size} TSLR (Student Loans) Eligibilities"
          insert_eligibilities
          student_loan_repayment_amount
        end

        private

        attr_reader :records, :logger, :school_id

        # the existing version of the activerecord-copy gem does not support
        # binary copy of decimals, so for now 'student_loan_repayment_amount' has been excluded
        # to solve this we use the student_loan_repayment_amount method to update
        # all of the student loans with a random value less than 5000
        def insert_eligibilities
          Policies::StudentLoans::Eligibility.copy_from_client ELIGIBILITY_COLUMNS do |copy|
            records.each do |data|
              time = Time.now.getutc

              subjects_taught ||= build_subjects_taught(data)
              copy << [
                1,
                schools_id,
                schools_id,
                0,
                true,
                subjects_taught[:biology_taught],
                subjects_taught[:chemistry_taught],
                subjects_taught[:physics_taught],
                subjects_taught[:computing_taught],
                subjects_taught[:languages_taught],
                # rand(4999),
                false,
                time,
                time
              ]
            end
          end
        end

        def student_loan_repayment_amount
          StudentLoans::Eligibility.all.each do |tslr_eligibility|
            tslr_eligibility.student_loan_repayment_amount = rand(4999)
            tslr_eligibility.save
          end
        end

        def schools_id
          School.find_by(name: "Penistone Grammar School").id
        end
      end
    end
  end
end
