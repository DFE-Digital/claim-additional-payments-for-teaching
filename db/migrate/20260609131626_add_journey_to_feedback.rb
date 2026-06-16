class AddJourneyToFeedback < ActiveRecord::Migration[8.1]
  def change
    add_column :feedbacks, :journey, :text
  end
end
