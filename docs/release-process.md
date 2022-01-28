# Release Process

## Get Approval

Contact the approver and other key stakeholders to obtain approval to release to
production and supply the created release note.

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

### 3. Testing

Perform exploratory testing on Azure TEST to ensure the service is working as
expected.

### 4. Push the tag

Once the pull request has been merged, create a tag against the merge commit in
the format `release-xxx` (zero-padded again) and push it to GitHub:

```sh
git tag release-xxx merge-commit-for-release
git push origin refs/tags/release-xxx
```

### 5. Trigger a production release in Azure DevOps

Once the build has passed for the newly tagged commit, you can deploy to
production as follows:

- Log in to this project on
  [Azure DevOps](https://dev.azure.com/dfe-ssp/S118-Teacher-Payments-Service).
- Navigate to Pipelines > Pipelines.
- Find the “Run” which corresponds to the merge commit created by merging the
  release pull request into `master`. This is the build which you want to
  release. You can filter by branch using the filter / funnel icon in the top
  right.
- Note the build number of this build (for example, `20210913.13`).
- Navigate to Pipelines > Releases.
- A release will have been created automatically off the successful build from
  master (above)
- The Release will ONLY deploy to DEV automatically
- To deploy to TEST click on the “Deploy Test” button that should have a blue
  icon in it.
- The Release will need to be approved to deploy to TEST.
- To deploy to Production click on “Deploy Production” and manually trigger the
  deployment by clicking on Deploy in the top menu then Deploy on the Deploy
  Release screen
- This deployment will also require approvals.

### 6. Database Migration

Follow the
[`guideline`](https://github.com/DFE-Digital/claim-additional-payments-for-teaching/blob/master/README.md#creating-data-migrations)
to run the database migration if required.

### 7. Announce the release in #claim_early_career_payments_tech

Post an update in the team's main Slack channel
#claim_early_career_payments_tech to let people know about the new release and
the changes that have just gone out.
