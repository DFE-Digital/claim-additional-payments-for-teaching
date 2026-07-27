class AdminMailer < ApplicationMailer
  def census_csv_processing_success(email_address)
    template_mail(
      CENSUS_CSV_PROCESSING_SUCCESS_ID,
      to: email_address,
      reply_to_id: GENERIC_NOTIFY_REPLY_TO_ID
    )
  end

  def census_csv_processing_error(email_address)
    template_mail(
      CENSUS_CSV_PROCESSING_ERROR_ID,
      to: email_address,
      reply_to_id: GENERIC_NOTIFY_REPLY_TO_ID
    )
  end

  def tps_csv_processing_success(email_address)
    template_mail(
      TPS_CSV_PROCESSING_SUCCESS_ID,
      to: email_address,
      reply_to_id: GENERIC_NOTIFY_REPLY_TO_ID
    )
  end

  def tps_csv_processing_error(email_address)
    template_mail(
      TPS_CSV_PROCESSING_ERROR_ID,
      to: email_address,
      reply_to_id: GENERIC_NOTIFY_REPLY_TO_ID
    )
  end

  def slc_csv_processing_success(email_address)
    template_mail(
      SLC_CSV_PROCESSING_SUCCESS_ID,
      to: email_address,
      reply_to_id: GENERIC_NOTIFY_REPLY_TO_ID
    )
  end

  def slc_csv_processing_error(email_address)
    template_mail(
      SLC_CSV_PROCESSING_ERROR_ID,
      to: email_address,
      reply_to_id: GENERIC_NOTIFY_REPLY_TO_ID
    )
  end

  def service_closing_soon(email_address, journey_name:, close_at:)
    template_mail(
      SERVICE_CLOSING_SOON_ID,
      to: email_address,
      reply_to_id: SERVICE_CLOSING_SOON_REPLY_TO_ID,
      personalisation: {
        journey_name:,
        close_at: close_at.strftime("%d %B %Y at %H:%M")
      }
    )
  end
end
