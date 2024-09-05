require "net/http"

class HeartbeatJob < CronJob
  self.cron_expression = "* * * * *"

  queue_as :heartbeat

  def perform
    if ENV.key?("HEARTBEAT_CHECK_URL") # Not available in dev and review environments
      uri = URI(ENV["HEARTBEAT_CHECK_URL"])
      res = Net::HTTP.get_response(uri)

      unless res.is_a?(Net::HTTPSuccess)
        Rails.logger.error "Error connecting to StatusCake: #{res.code} #{res.msg}"
      end
    end
  end
end
