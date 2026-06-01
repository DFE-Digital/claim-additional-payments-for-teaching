class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    create_table :feedbacks, id: :uuid do |t|
      t.text :rating
      t.text :area
      t.text :specific_page
      t.text :comment
      t.boolean :research_participation
      t.citext :email_address
      t.text :occupation
      t.text :origin
      t.uuid :claim_id

      t.timestamps
    end
  end
end
