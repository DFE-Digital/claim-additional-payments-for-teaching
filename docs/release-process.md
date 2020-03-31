# Release Process

When releasing code, we take the view that the `master` branch is always
deployable. Whenever we merge a branch into `master`, this is automatically
deployed to our development environment in the DfE Cloud Platform.

To deploy to production, we take the following steps.

## 1. Update the Changelog and create a pull request

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

## 2. Confirm the release and review the pull request

The pull request should be reviewed to confirm that the changes currently in
staging are safe to ship and that [`CHANGELOG.md`](../CHANGELOG.md) accurately
reflects the changes included in the release:

- Confirm the release with any relevant people (for example the product owner)
- Think about any dependencies that also need considering: dependent parts of
  the service that also need updating; environment variables that need
  changing/adding; third-party services that need to be set up/updated

## 3. Push the tag

Once the pull request has been merged, create a tag against the merge commit in
the format `release-xxx` (zero-padded again) and push it to GitHub:

```sh
git tag release-xxx merge-commit-for-release
git push origin refs/tags/release-xxx
```

## 4. Trigger a production release in Azure DevOps

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

## 5. Update Trello

The cards in the "Next release" column that relate to code that has just been
released should be moved to the top of the "Done" column.

## 6. Announce the release in #twd_claim_payments

Post an update in the team's main Slack channel #twd_claim_payments to let
people know about the new release and the changes that have just gone out.
