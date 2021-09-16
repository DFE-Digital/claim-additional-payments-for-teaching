module SendAnalytics
  class DailyStats < Base
    private

    def file_name
      @file_name ||=
        "daily-stats/daily-stats-analytics_#{date.strftime("%Y%m%d")}.csv"
    end

    def csv
      @csv ||=
        ::ClaimStats::Daily.to_csv(date: date)
    end
  end
end
