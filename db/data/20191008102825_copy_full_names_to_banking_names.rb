class CopyFullNamesToBankingNames < ActiveRecord::Migration[5.2]
  def up
    Claim.where(banking_name: nil).each do |c|
      c.update_attribute(:banking_name, c.full_name)
    end
  end

  def down
    Claim.update_all(banking_name: nil)
  end
end
