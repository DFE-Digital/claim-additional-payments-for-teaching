# Developer onboarding

The audience for this document is a developer who is being onboarded onto the
project, either for the service team or first-line support.

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
