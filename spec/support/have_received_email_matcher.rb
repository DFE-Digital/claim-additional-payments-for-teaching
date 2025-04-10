RSpec::Matchers.define :have_received_email do |template_id, expected_personalisation|
  expected_personalisation ||= {}

  match do |email_address|
    emails = ActionMailer::Base.deliveries.select do |mail|
      mail.to.include? email_address
    end

    matching_templates = emails.select do |email|
      email.template_id == template_id
    end.compact

    personalisation_fields = matching_templates.map do |email|
      email.personalisation
    end.compact

    personalisation_fields.any? do |personalisation|
      expected_personalisation.all? do |key, value|
        personalisation[key] == value
      end
    end
  end

  failure_message do |email_address|
    found = ActionMailer::Base.deliveries.map do |mail|
      <<-TEXT.squish
        To: #{mail.to} -
        template id: #{mail.try(:template_id)} -
        personalisation: #{mail.personalisation}"
      TEXT
    end

    message = <<~MSG.squish
      Expected `ActionMailer::Base.deliveries` to include an email to
      #{email_address}` with template_id `#{template_id}` and personalisation
      `#{expected_personalisation}` but
      no such email could be found.
    MSG

    message << "\n\n"

    message << if found.any?
      "The following emails were found: \n #{found.join("\n")}"
    else
      "`ActionMailer::Base.deliveries` was empty"
    end
  end
end
