class ClaimMailer < Mail::Notify::Mailer
  def submitted(claim)
    view_mail_with_claim_and_subject(claim, "Your claim was received")
  end

  def approved(claim)
    view_mail_with_claim_and_subject(claim, "Your claim to get your student loan repayments back has been approved, reference number: #{claim.reference}")
  end

  private

  def view_mail_with_claim_and_subject(claim, subject)
    @claim = claim
    @display_name = [claim.first_name, claim.surname].join(" ")

    view_mail(
      ENV["NOTIFY_TEMPLATE_ID"],
      to: @claim.email_address,
      subject: subject
    )
  end
end
