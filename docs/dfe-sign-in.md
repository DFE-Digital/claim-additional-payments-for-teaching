# DfE Sign-in

DfE Sign-in is DfE’s single sign-on service. We use it to restrict access to
`/admin`.

The project’s Confluence wiki contains
[instructions](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/1102053404/Granting+and+revoking+access+to+back-office)
on how to add new service operators to the production environment.

# Adding a new user to the pre-production environment

Our app's development environment uses the pre-production environment of DfE
Sign-in. Unlike the production environment, you can create your own account for
the pre-production environment. You will still need make a request to be added
to an organisation and our service.

Follow these steps to get access to the pre-production environment:

1. Go to https://pp-services.signin.education.gov.uk/ and click the "Start now"
   button.
2. Click the “create a DfE Sign-in account” link and create an account (probably
   best to use your DfE email address).
3. Security approval is required
   This is obtained via the self-service portal
   [Raise a ticket in Service Portal](https://dfe.service-now.com/serviceportal)
   _**N.B.**_ If you are not on a `DfE device` a request for external access can be raised by
   a manager or colleague with a `DfE device` via
   Requests > Accounts and Access > Service Portal - External BOYD Access to the
   Self-Service portal ONLY (You will need to provide a DfE email address)
   >The wording for the request is "please can you invite first_name.last_name@digital.education.gov.uk
   >to the Group Access Policy that restricts access to the Claim additional payments for teaching service,
   >and add them to this service with the Service Operator role."
4. DSI change team approval is required.
5. Now wait until this is granted.
