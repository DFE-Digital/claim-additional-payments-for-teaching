# Connect to an instance running in Azure

This Rails app runs on the
[Teacher Services Cloud](https://github.com/DFE-Digital/teacher-services-cloud)
Kubernetes infrastructure in Azure.

Follow these instructions to [run a Rake task](#run-a-rake-task) or
[open a Rails console](#open-a-rails-console).

> [!NOTE] These instructions are for connecting to the `test` Kubernetes cluster
> which powers our **Test and PR review environments**.
>
> We don't have a production environment yet – but when we do, we will update
> these instructions accordingly.

## 1. Authenticate to the Kubernetes cluster

You'll need to configure your command line console so it can connect to the
Kubernetes cluster. Your authenticated state should persist for several days,
but you may need to re-authenticate every once in a while.

1. Login to the [Microsoft Azure portal](https://portal.azure.com)

   > Use your `@digitalauth.education.gov.uk` account.
   >
   > Make sure it says "DfE Platform Identity" in the top right corner of the
   > screen below your name. If not, click the settings/cog icon and choose it
   > from the list of directories.

2. Open a console. Navigate to the `claim-additional-payments-for-teaching` repo
   directory and run:

   ```shell
   az login
   ```

   > If you have trouble logging in, try switching browser. Chrome is known to
   > be buggy with this step, so copy & paste the URL into Safari instead.
   >
   > Otherwise you might have more success with this command:
   >
   > ```shell
   > az login --use-device-code
   > ```

3. Install kubetctl:

   ```shell
   brew install Azure/kubelogin/kubelogin
   ```

4. Then run:

   ```shell
   make review-aks get-cluster-credentials PR_NUMBER=1
   ```

   > You can pass in anything as the PR_NUMBER argument for this command; it
   > doesn't even need to match a current PR.

5. Assuming everything worked correctly, you should now be able to access the
   Kubernetes cluster using the `kubectl` command.

   > You can test you have access by running this command:
   >
   > ```shell
   > kubectl -n srtl-development get deployments
   > ```
   >
   > You should see a list of Kubernetes deployments.

## 2. Get the Kubernetes Deployment name

Multiple instances of the app run on the `test` cluster, one for each Pull
Request that has a `deploy` label. Each one is a Kubernetes
[Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
resource.

To connect to a **review app**, the deployment is named after the PR number
followed by either web, postgres or worker:

```shell
claim-additional-payments-for-teaching-review-[PR_NUMBER]-web
claim-additional-payments-for-teaching-review-[PR_NUMBER]-postgres
claim-additional-payments-for-teaching-review-[PR_NUMBER]-worker
```

For example, the worker for PR 123 would be
`claim-additional-payments-for-teaching-review-123-worker`.

> [!TIP] For a list of all active deployments, run:
>
> ```shell
> kubectl -n srtl-development get deployments
> ```

## 3. Connect to a running container

These commands will connect to a review app.

### Open a Rails console

Open an interactive Rails console using this command:

```shell
kubectl -n srtl-development exec -it deployment/claim-additional-payments-for-teaching-review-123-worker -- rails console
```

### Open a shell console

Open an interactive Linux shell using this command:

```shell
kubectl -n srtl-development exec -it deployment/claim-additional-payments-for-teaching-review-123-worker -- sh
```

### Run a Rake task

Run Rake tasks using this command:

```shell
kubectl -n srtl-development exec -it deployment/claim-additional-payments-for-teaching-review-123-worker -- rake [TASK_TO_RUN]
```

Or list all available Rake tasks with:

```shell
kubectl -n srtl-development exec -it deployment/claim-additional-payments-for-teaching-review-123-worker -- rake -T
```

## Useful links

- [Teacher Services Cloud documentation](https://github.com/DFE-Digital/teacher-services-cloud/tree/main/documentation)
- [Developer onboarding](https://github.com/DFE-Digital/teacher-services-cloud/blob/main/documentation/developer-onboarding.md)
  for the Teacher Services Cloud
- If in doubt, ask in the
  [#teacher-services-infra](https://ukgovernmentdfe.slack.com/archives/C011EM7HU85)
  Slack channel
