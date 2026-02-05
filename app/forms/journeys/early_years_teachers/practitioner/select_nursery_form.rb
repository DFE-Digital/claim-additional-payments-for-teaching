module Journeys
  module EarlyYearsTeachers
    module Practitioner
      class SelectNurseryForm < Form
        attribute :nursery_id, :string
        attribute :nursery_search, :string

        validates :nursery_id,
          presence: {message: i18n_error_message(:blank)}

        def save
          return false unless valid?
          journey_session.answers.assign_attributes(nursery_id: nursery_id)
          journey_session.save!
        end
      end
    end
  end
end
