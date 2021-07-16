# Release Process

## Get Approval

### 1. Create Release Note documentation

Create a release note (using the ECP Beta Release Note template) by creating a
new confluence page and changing the title to correspond with the release number
under the Release Process confluence page and the page must have the following
information e.g.
[`Release 1`](https://dfedigital.atlassian.net/wiki/spaces/TP/pages/3021406211/Release+1)
Information | Notes --- | --- Release Date | Planned production release date
Approver | Name of the person who is going to approve the release Approval Date
| The date approval was granted Status | Set the PENDING status, when the team
is ready to release in production. Summary | Provide a short summary of the
release and it’s associated business value Important highlights from this
release | High level explanation of what is included in this release. NOTE: This
section and CHANGELOG release notes must match. All update for this release |
Provide a list of Jira tickets that are going to released with links to the Jira
issue. Tickets should be split into the features and bugs section of the note.
Testing | Provide the testing approach you are taking/have taken for the release
and links to any results/reports from lower environment testing. Rollback |
Define the rollback plan if the event that the release doesn’t go as planned.
Failover Plan | Define the failover plan in the event of catastrophic failure.

### 2. Get Approval

Send an email to the approver and other key stakeholders to obtain approval to
release to production and supply the created release note.

### 3. After Approval

Update the Release note with the following information

- Change the status from PENDING to APPROVED
- Set the approval date.

## Conduct Release

When releasing code, we take the view that the `master` branch is always
deployable. Whenever we merge a branch into `master`, this is automatically
deployed to our development environment in the DfE Cloud Platform.

To deploy to production, we take the following steps.

### 1. Update the Changelog and create a pull request

- Create a branch from `master` for the release called `release-xxx` where `xxx`
  is the release number (a 3 digit number padded with zeros)
- Move all features from the `Unreleased` section of
  [`CHANGELOG.md`](../CHANGELOG.md) to a new heading with the release number
  linked to a diff of the two latest versions, together with the date in the
  following format:

  ```markdown
  ## [Release XXX] - 2019-01-01

  ...

  [release xxx]:
    https://github.com/DFE-Digital/dfe-teachers-payment-service/compare/previous-release...release-xxx
  ```

- Create a commit for the release, including the changes for the release in the
  commit message
- Push the branch
- Open a pull request and get it reviewed

### 2. Confirm the release and review the pull request

The pull request should be reviewed to confirm that the changes currently in
staging are safe to ship and that [`CHANGELOG.md`](../CHANGELOG.md) accurately
reflects the changes included in the release:

- Confirm the release with any relevant people (for example the product owner)
- Think about any dependencies that also need considering: dependent parts of
  the service that also need updating; environment variables that need
  changing/adding; third-party services that need to be set up/updated

### 3. Push the tag

Once the pull request has been merged, create a tag against the merge commit in
the format `release-xxx` (zero-padded again) and push it to GitHub:

```sh
git tag release-xxx merge-commit-for-release
git push origin refs/tags/release-xxx
```

### 4. Trigger a production release in Azure DevOps

Once the build has passed for the newly tagged commit, you can deploy to
production as follows:

- Log in to this project on
  [Azure DevOps](https://dev.azure.com/dfe-ssp/S118-Teacher-Payments-Service).
- Navigate to Pipelines > Pipelines.
- Find the "Run" which corresponds to the merge commit created by merging the
  release pull request into `master`. This is the build which you want to
  release. You can filter by branch using the filter / funnel icon in the top
  right.
- Note the build number of this build (for example, `20190717.2`).
- Navigate to Pipelines > Releases.
- Click on the "Deploy" pipeline.
- Click on the release matching the build number of the build you want to
  release.
- Click on "Deploy Production" and manually trigger the deployment.

### 5. Database Migration

Follow the
[`guideline`](https://github.com/DFE-Digital/claim-additional-payments-for-teaching/blob/master/README.md#creating-data-migrations)
to run the database migration if required.

### 6. Testing

Perform exploratory testing and ensures the service is working as expected. Also
ensures that the service’s webtests and health check tests are passing.

### 7. Update Confluence page

Update the SUCCESS or FAIL status information on the release document on the
confluence page.

### 8. Announce the release in #twd_claim_payments

Post an update in the team's main Slack channel #twd_claim_payments to let
people know about the new release and the changes that have just gone out.
