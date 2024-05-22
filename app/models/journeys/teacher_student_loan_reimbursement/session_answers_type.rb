module Journeys
  module TeacherStudentLoanReimbursement
    class SessionAnswersType < ActiveModel::Type::Value
      def type
        :jsonb
      end

      def cast_value(value)
        case value
        when String
          decoded = begin
            ActiveSupport::JSON.decode(value)
          rescue
            nil
          end
          SessionAnswers.new(decoded) unless decoded.nil?
        when Hash
          SessionAnswers.new(value)
        when SessionAnswers
          value
        end
      end

      def serialize(value)
        case value
        when Hash, SessionAnswers
          ActiveSupport::JSON.encode(value)
        else
          super
        end
      end

      def changed_in_place?(raw_old_value, new_value)
        cast_value(raw_old_value) != new_value
      end
    end
  end
end
