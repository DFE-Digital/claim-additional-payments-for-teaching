desc "Retrieve recent message delivery status from GOV.UK Notify API"
task :retrieve_notify_message_status, [:number_of_days] => :environment do |t, args|
  args.with_defaults(number_of_days: 1)

  require "notifications/client"
  client = Notifications::Client.new(ENV.fetch("NOTIFY_API_KEY"))

  current_message_timestamp = Time.now
  oldest_retained_message_timestamp = current_message_timestamp - args.number_of_days.days

  messages = []
  response = nil

  while current_message_timestamp > oldest_retained_message_timestamp
    args = {}
    args[:older_than] = response.collection.last.id if response.present?

    puts "Retrieving messages older than #{current_message_timestamp}"

    response = client.get_notifications(args)

    messages.push(*response.collection)

    current_message_timestamp = response.collection.last.created_at
  end

  puts "Retrieved #{messages.count} messages"

  CSV.open("notifications.csv", "w") do |csv|
    csv << ["Email", "Status", "Template ID", "Sent at", "Created at", "Completed at"]

    messages.each do |message|
      csv << [message.email_address, message.status, message.template["id"], message.sent_at, message.created_at, message.completed_at]
    end
  end

  puts "Written to notifications.csv"
end
