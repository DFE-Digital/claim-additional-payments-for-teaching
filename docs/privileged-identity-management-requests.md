# Privileged Identity Management (PIM) requests

Accessing resources in the `production` or `test` environments requires elevated
privileges. We do this through Azure’s Privileged Identity Management (PIM)
request system.

To make a PIM request:

1. Visit
   [this page](https://portal.azure.com/#blade/Microsoft_Azure_PIMCommon/ActivationMenuBlade/azurerbac).
2. Activate the ‘Contributor’ role for the environment you want to access.
3. Give a reason for your request and submit.
4. The request must now be approved:
   - For the `production` environment, you will have to wait until this has been
     [approved by another team member](#approving-a-pim-request).
   - For `test`, the request is automatically approved.

## Approving a PIM request

Only
[members](https://portal.azure.com/#blade/Microsoft_AAD_IAM/GroupDetailsMenuBlade/Members/groupId/407a4183-b6a3-4186-a766-9d342935127e)
of the “s118-teacherpaymentservice-Managers USR” Active Directory group can
approve a PIM request.

When somebody makes a PIM request, anyone who can approve it should receive an
email to their `@digital.education.gov.uk` address. If not, they can view all
pending requests
[here](https://portal.azure.com/?Microsoft_Azure_PIMCommon=true#blade/Microsoft_Azure_PIMCommon/ApproveRequestMenuBlade/azurerbac).
