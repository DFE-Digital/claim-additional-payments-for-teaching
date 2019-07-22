class ChangeQtsYearToInteger < ActiveRecord::Migration[5.2]
  def up
    change_column :tslr_claims, :qts_award_year, "integer USING CASE qts_award_year
        WHEN '2013-2014' THEN 1
        WHEN '2014-2015' THEN 2
        WHEN '2015-2016' THEN 3
        WHEN '2016-2017' THEN 4
        WHEN '2017-2018' THEN 5
        WHEN '2018-2019' THEN 6
        WHEN '2019-2020' THEN 7
      END"
  end

  def down
    change_column :tslr_claims, :qts_award_year, "varchar USING CASE qts_award_year
        WHEN 1 THEN '2013-2014'
        WHEN 2 THEN '2014-2015'
        WHEN 3 THEN '2015-2016'
        WHEN 4 THEN '2016-2017'
        WHEN 5 THEN '2017-2018'
        WHEN 6 THEN '2018-2019'
        WHEN 7 THEN '2019-2020'
      END"
  end
end
