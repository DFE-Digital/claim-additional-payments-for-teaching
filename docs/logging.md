# Logging

# Application-level logging in logit.io

The application sends all Rails logs to [logit.io](https://logit.io/). This
gives us a hosted ELK stack. ELK stands for Elasticsearch, Logstash, Kibana.
It’s a open-source stack frequently used for log aggregation and visualisation.

Kibana is the tool that you’ll use to explore the logs.

To view the production logs in Kibana:

1. Log in to logit.io.
2. Click on the “DfE Claim” account.
3. Find the “Production” stack and click “Launch Kibana”.

## Missing logs in logit.io

At the time of writing (2020-03-26), we have a problem where some log messages
seem to be missing from logit.io. We are trying to fix this in
[this Trello card](https://trello.com/c/JN44De4l/1330-understand-why-expected-logs-arent-in-logit).

# Azure logs

We should aim for logit.io to be the single place developers need to look to
find logs. However, it’s useful to know about some of the logs that are
available from Azure.

The `az` Azure command line tool has some useful commands for interacting with
logs.

## App Service

The App Service handles HTTP traffic.

There is some
[Azure documentation](https://docs.microsoft.com/en-us/azure/app-service/troubleshoot-diagnostic-logs#access-log-files)
about the logs available for an App Service. Here we go over some of the ways to
extract these logs.

### Docker logs

To view Docker logs in production, you will need to elevate your privileges
using a [PIM request](privileged-identity-management-requests.md).

You can use the `az webapp log` commands to tail and download the logs.

Here’s an example command that will live tail the container logs and Docker host
logs, for `production`:

```
az webapp log tail --name s118p01-app-as --resource-group s118p01-app --subscription s118-teacherpaymentsservice-production
```

Or, you can download them with a browser:

- production Docker logs from the instances currently in the App Service:
  https://s118p01-app-as.scm.azurewebsites.net/api/logs/docker
- production Docker logs from current and previous instances:
  https://s118d01-app-as.scm.azurewebsites.net/api/vfs/LogFiles/

### Application Insights

The Rails application uses the `application_insights` gem, which sends
information about each request to Azure’s Application Insights service. If
you’re struggling to find request logs in logit.io, you could try looking here.

To view these logs:

1. Visit `https://portal.azure.com`.
2. Search for `s118p01-app-ai`.
3. Click “Logs” under “Monitoring” on the left.
4. You can now execute queries. For example, to view all requests, type
   `requests` in the query field, and click Run.

## Container Instances

The container instances perform other tasks like running a background job
worker. The logs are lost after a deploy. You don’t need PIM-elevated privileges
to view the container instance logs.

To view the logs for a container instance, we can use `az container logs`:

```
az container logs --name s118p01-app-worker-aci --resource-group s118p01-app --subscription s118-teacherpaymentsservice-production
```

Or, you can view them in a browser:

1. Visit `https://portal.azure.com`.
2. Search for `s118p01-app-worker-aci`.
3. Click “Containers” on the left.
4. Click “Logs”.
