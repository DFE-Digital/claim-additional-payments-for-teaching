# Privileged Identity Management (PIM) requests

Accessing resources in the production environment requires elevated privileges.
We do this through Azure’s Privileged Identity Management (PIM) request system.

To make a PIM request:

1. Visit
   [this page](https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ActivationMenuBlade/~/aadgroup).
2. Activate the 'Member' role for the `s189 SRTL production PIM` group.
3. Give a reason for your request and submit.
4. The request must now be approved
   [by another team member](#approving-a-pim-request).

## Approving a PIM request

Only members of the
[s189 SRTL delivery team](https://portal.azure.com/#view/Microsoft_AAD_IAM/GroupDetailsMenuBlade/~/Overview/groupId/f50f3249-db5d-4d96-a123-cd1ef84536c3)
can approve a PIM request.

You can view all pending requests
[here](https://portal.azure.com/#view/Microsoft_Azure_PIMCommon/ApproveRequestMenuBlade/~/aadmigratedroles).
