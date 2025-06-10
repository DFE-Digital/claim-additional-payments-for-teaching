module DfeSignIn
  class SlackNotification
    def initialize(user_uuid)
      @user = DfeSignIn::User.find(user_uuid)
    end

    def run
      notifier.ping "A new user has been granted access to the Claim admin panel: #{@user.given_name} #{@user.family_name} - #{@user.organisation_name} (#{@user.email})"
    end

    private

    def notifier
      @notifier ||= Slack::Notifier.new(url)
    end

    def url
      ENV.fetch("DFE_SIGN_IN_SLACK_NOTIFICATION_WEBHOOK_URL")
    end
  end
end
