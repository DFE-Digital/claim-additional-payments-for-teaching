module Dqt
  class Api
    class V1
      class QualifiedTeachingStatus
        def initialize(response:)
          self.response = response
        end

        def id
          integer_reader(response[:id])
        end

        def teacher_reference_number
          string_reader(response[:trn])
        end

        def first_name
          string_reader(response[:name]) do |string|
            string.split.first
          end
        end

        def surname
          string_reader(response[:name]) do |string|
            string.split.last
          end
        end

        def date_of_birth
          date_reader(response[:doB])
        end

        def degree_codes
          []
        end

        def national_insurance_number
          string_reader(response[:niNumber]) do |string|
            string.strip
          end
        end

        def qts_award_date
          date_reader(response[:qtsAwardDate])
        end

        def itt_subject_codes
          (1..3).filter_map do |n|
            string_reader(response[:"ittSubject#{n}Code"])
          end
        end

        def active_alert?
          boolean_reader(response[:activeAlert])
        end

        def qualification_name
          string_reader(response[:qualificationName]) do |string|
            string.strip
          end
        end

        def itt_start_date
          date_reader(response[:ittStartDate])
        end

        private

        attr_accessor :response

        def date_reader(value)
          return if nil_value?(value)

          begin
            Date.parse(value)
          rescue Date::Error, TypeError
            begin
              Time.at(Integer(value), in: "UTC").to_date
            rescue ArgumentError => e
              Rollbar.error(e)

              nil
            end
          end
        end

        def boolean_reader(value)
          return if nil_value?(value)

          value.to_s.strip.downcase == "true"
        end

        def integer_reader(value)
          return if nil_value?(value)

          begin
            Integer(value)
          rescue ArgumentError => e
            Rollbar.error(e)

            nil
          end
        end

        def string_reader(value)
          return if nil_value?(value)

          value = value.to_s
          value = yield value if block_given?

          value
        end

        def nil_value?(value)
          value.nil? ||
            ["nil", "null"].any?(
              value
                .to_s
                .strip
                .downcase
            )
        end
      end
    end
  end
end
