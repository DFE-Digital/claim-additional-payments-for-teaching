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
3. In `ukgovernmentdfe.slack.com`’s `#dfe_sign-in`, write something like
   > I have started as a developer on the "Claim additional payments for
   > teaching" service. On pre-prod, please can you add me to the Department for
   > Education organisation, and give me access to this service, with the
   > Service Operator role?
4. Now wait until this is granted.
