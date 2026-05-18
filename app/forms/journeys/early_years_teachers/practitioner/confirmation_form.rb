module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class ConfirmationForm < Form
        def reference
          "ABC123456"
        end

        def email_address
          "test@example.com"
        end
      end
    end
  end
end
