# Logging

The application logs to STDOUT in JSON format using [Semantic Logger](https://github.com/reidmorrison/rails_semantic_logger).

# AKS/container logs

Logs are available via the standard Azure/AKS tooling.

The `az` Azure command line tool and `kubectl` have some useful commands for interacting with
logs.

```sh
kubectl -n srtl-test get pods
kubectl -n srtl-test logs claim-additional-payments-for-teaching-test-web-123456
```

You will need PIM elevated privileges to view logs for production.

# Logit.io

Logs are shipped to [Logit.io](https://logit.io/) automatically by AKS. You will need an account to access this service.

## App Service

The App Service handles HTTP traffic.

There is some
[Azure documentation](https://docs.microsoft.com/en-us/azure/app-service/troubleshoot-diagnostic-logs#access-log-files)
about the logs available for an App Service. Here we go over some of the ways to
extract these logs.

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
