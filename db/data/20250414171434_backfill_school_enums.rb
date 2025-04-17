# Run me with `rails runner db/data/20250414171434_backfill_school_enums.rb`

School.reorder(id: :asc).in_batches(of: 1000) do |schools|
  schools.each do |school|
    school.update!(
      phase_string: school.phase,
      school_type_group_string: school.school_type_group,
      school_type_string: school.school_type
    )
  end
end

# Verify with the following queries
# - select phase_string, count(*) from schools group by phase_string order by count(*) ;
# - select phase, count(*) from schools group by phase order by count(*) ;
#
# - select school_type_group_string, count(*) from schools group by school_type_group_string order by count(*) ;
# - select school_type_group, count(*) from schools group by school_type_group order by count(*) ;
#
# - select school_type_string, count(*) from schools group by school_type_string order by count(*) ;
# - select school_type, count(*) from schools group by school_type order by count(*) ;
