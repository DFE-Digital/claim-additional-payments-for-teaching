# Run me with `rails runner db/data/20200318093820_update_manual_on_tasks.rb`

Task.where(manual: nil).update_all(manual: true)
