# DfE Sign-in

DfE Sign-in is DfE’s single sign-on service. We use it to restrict access to
`/admin`.

The project’s Confluence wiki contains
[instructions](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1102053404/Granting+and+revoking+access+to+back-office)
on how to add new service operators to the production environment.

## Adding a new user to the pre-production environment

The app's development environment uses the pre-production environment of DfE
Sign-in. Unlike the production environment, you can create your own account for
the pre-production environment. You will still need make a request to be added
to an organisation and our service.

Follow these steps to get access to the pre-production environment:

### Create a DfE Account

1. Go to https://pp-services.signin.education.gov.uk/ and click the "Start now"
   button.
2. Click the “create a DfE Sign-in account” link and create an account (probably
   best to use your DfE email address).

### Obtain DSI (DfE Sign In) Approval

DSI change team approval is required. This is obtained via the service desk and
should be requested by a Claims Team member on the developers behalf

1. [Raise a ticket in Service Desk](https://<checking.link.with.claims.team>)
2. Select `Dfe sign in requests`
3. The wording for the `business benefits` is
   > "I need first_name.last_name@digital.education.gov.uk to have access to DfE
   > sign in to enable them to make improvements and changes to the Claim
   > Additional Payments admin site. The Claim team themselves will be
   > positively impacted by the completion of these improvements."
4. Fill in anappropriate date for the `Proposed delivery date`
5. The wording for the `Describe request` is
   > "Please can you invite first_name.last_name@digital.education.gov.uk to the
   > Group Access Policy that restricts access to the Claim additional payments
   > for teaching service, and add them to this service with the Service
   > Operator role."
6. Press `Submit` to send the form for approval.
7. Now wait until this is granted.

### Using the Access

Once granted any requests in pre-production environments to `/admin` will
display the `DfE Sign In` button. Click this then fill-in the username and
password provided in Step 2 of Create a DfE Account. If given the option select
`Teacher Services`
