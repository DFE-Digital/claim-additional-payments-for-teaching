# Run me with `rails runner db/data/20200311111523_set_passed_status_on_old_tasks.rb`
Task.where(passed: nil).update_all(passed: true)
