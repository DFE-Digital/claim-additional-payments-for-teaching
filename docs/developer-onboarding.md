# Developer onboarding

The audience for this document is a developer who is being onboarded onto the
project, either for the service team or first-line support.

## First-line support onboarding

1. Product owner in DfE follows the
   [first-line support developer onboarding steps in Confluence](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1490452481/Onboarding+a+first-line+support+developer).
2. The new developer follows the
   [self-service onboarding instructions](#self-service-onboarding-for-first-line-support).

### Self-service onboarding for first-line support

Before you start, you will need:

- an `@digital.education.gov.uk` email address
- an invitation to the DfE Platform Identity organisation in Azure Active
  Directory – this should be in your DfE email inbox, once you follow the first
  steps below to log in

Then, follow these steps to complete your onboarding:

1. Log in to your DfE email.
2. If Google asks you to set up two-factor authentication, see
   [this advice](#how-to-set-up-two-factor-auth-for-your-digitaleducationgovuk-google-account).
3. Follow the link in the Azure invitation email and create an account.
4. Click on
   [this link](https://portal.azure.com/?Microsoft_Azure_PIMCommon=true#blade/Microsoft_AAD_IAM/GroupDetailsMenuBlade/Owners/groupId/6642920a-1aab-49bb-9a20-365131195349)
   – we’ll use this to confirm you’re using the correct directory in Azure.
5. If you see an error about “the group could not be found”, then click on your
   email address in the top right, choose “Switch directory”, and switch to “DfE
   Platform Identity”.
6. If Azure asks you to set up two-factor authentication, see
   [this advice](#how-to-set-up-azure-two-factor-auth-without-giving-a-phone-number-or-downloading-a-special-app).
7. Ask one of the
   [owners](https://portal.azure.com/?Microsoft_Azure_PIMCommon=true#blade/Microsoft_AAD_IAM/GroupDetailsMenuBlade/Owners/groupId/6642920a-1aab-49bb-9a20-365131195349)
   of the “s118-teacherpaymentservice-Delivery Team USR” Active Directory group
   to follow
   [these instructions](#how-to-add-a-member-to-the-delivery-team-in-azure) to
   add you as a member.
8. Sign up for [DfE Digital’s Confluence wiki](https://dfedigital.atlassian.net)
   using your DfE email address.
9. Follow these steps from the
   [onboarding page in Confluence](https://dfedigital.atlassian.net/wiki/spaces/TP):
   - Slack
   - GitHub
   - logit.io – the Viewers team is sufficient for support needs
   - Rollbar

## How to set up two-factor auth for your `@digital.education.gov.uk` Google account

At the time of writing (2020-04-06), new DfE Google users must set up two-factor
authentication (2FA) within 24 hours of first login.

When setting up 2FA for the first time, the only authentication methods which
DfE’s configuration allows are:

- phone call or SMS
- installing the Google app on a smartphone – not to be confused with Google
  Authenticator / TOTP
- a physical security key – FIDO U2F standard

If you do not want to give Google your phone number or do not have a physical
security key, you can
[use your Android phone as a security key](https://support.google.com/accounts/answer/9289445),
or use the Google Smart Lock iOS app as a security key.

If you do not want to use your phone at all, you can use a software tool which
fakes a physical security key. One example is
[SoftU2F](https://github.com/github/SoftU2F). I’ve tried using this, and it
works.

After setting up 2FA for the first time, you can visit
https://accounts.google.com and add additional authentication methods such as
Google Authenticator, which lets you use a generic TOTP authentication app like
1Password. You can then remove the initial authentication method.

## How to set up Azure two-factor auth without giving a phone number or downloading a special app

The first time you try to use DfE’s Cloud Infrastructure Platform – for example
by switching to the “DfE Platform Identity” subscription in the Azure Portal –
it will ask you to set up two-factor authentication.

If you don’t want to give them your phone number or install the Microsoft
authenticator app, you can use a generic TOTP authenticator app like 1Password.

These steps are correct for DfE Azure’s UI as of 2020-03-31, but things might
change.

1. In “Step 1: How should we contact you?”, choose “Mobile app”.
2. In “How do you want to use the mobile app?”, choose “Use verification code”.
3. Click the “Set up” button.
4. The “Configure mobile app” screen that appears will show a QR code that can
   only be used by the Microsoft authenticator app. To switch it to display a
   TOTP code, click “Configure app without notifications”. You can then copy and
   paste the “Secret Key” into a one-time password field in your authenticator
   app.
5. Click “Next”.
6. Enter the 6-digit verification code displayed in your authenticator app.
7. Click “Verify”.
8. It might also ask you for a phone number after this. Click “Finished” without
   entering a phone number.

After displaying a validation error on the phone number field, it will still
proceed. Two-factor auth is now set up.

## How to add a member to the delivery team group in Azure

1. Go to
   https://portal.azure.com/#blade/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/Overview.
2. Confirm that it says “DfE Platform Identity” – if not, use the “switch
   directory” button.
3. In Groups, search for “s118-teacherpaymentservice-Delivery Team USR”.
4. Add the new person.
