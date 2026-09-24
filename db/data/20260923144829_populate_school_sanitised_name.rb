# Run me with `rails runner db/data/20260923144829_populate_school_sanitised_name.rb`

School.update_all("name_sanitised = regexp_replace(\"name\", '\\W', '', 'g')")
