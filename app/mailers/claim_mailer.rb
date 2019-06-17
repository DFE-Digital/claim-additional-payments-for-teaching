class ClaimMailer < Mail::Notify::Mailer
  def submitted(claim)
    @claim = claim
    view_mail(
      ENV["NOTIFY_TEMPLATE_ID"],
      to: @claim.email_address,
      subject: "Your claim was received"
    )
  end
end
