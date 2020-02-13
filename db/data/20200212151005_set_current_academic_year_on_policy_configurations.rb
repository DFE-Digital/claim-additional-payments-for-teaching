# Run me with `rails runner db/data/20200212151005_set_current_academic_year_on_policy_configurations.rb`

PolicyConfiguration.update_all(current_academic_year: "2019/2020")
