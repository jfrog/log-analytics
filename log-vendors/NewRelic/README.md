# New Relic Integration

## Versions Supported

This integration is last tested with Artifactory 7.77.11 and Xray 3.88.12 versions.

## New Relic Setup

New Relic setup can be done by going through the onboarding steps below or by using license key directly if one exists. If a license key exists, use the New Relic Fluentd plugin to forward logs, violations and metrics directly to your New Relic account.

* Create an account in New Relic
* From the account dropdown, click API keys
* Copy the license key which is also referenced in the UI as ingest - license

## Dashboards

### Adding JFrog dashboards

In the New Relic UI, on the left menu go to `Add Data` -> `All` -> `Search Bar` and search for `jfrog`. From the results choose `Dashboards` and add the JFrog dashboards

### Artifactory dashboard

JFrog Artifactory Dashboard is divided into three sections Application, Audit, Requests and Docker

* **Application** - This section tracks Log Volume (information about different log sources) and Artifactory Errors over time (bursts of application errors that may otherwise go undetected)
* **Audit** - This section tracks audit logs help you determine who is accessing your Artifactory instance and from where. These can help you track potentially malicious requests or processes (such as CI jobs) using expired credentials
* **Requests** - This section tracks HTTP response codes, top 10 IP addresses for uploads and downloads
* **Docker** - To monitor Dockerhub pull requests users should have a Dockerhub account either paid or free. Free accounts allow up to 200 pull requests per 6 hour window. Various widgets have been added in the new Docker tab under Artifactory to help monitor your Dockerhub pull requests. An alert is also available to enable if desired that will allow you to send emails or add outbound webhooks through configuration to be notified when you exceed the configurable threshold
* **Metrics** - To gain insights into the system performance, storage consumption, and connection statistics associated with JFrog Artifactory

### Xray dashboard

JFrog Xray Dashboard is divided into two sections Logs and Violations

* **Logs** - This dashboard provides a summary of access, service and traffic log volumes associated with Xray. Additionally, customers are also able to track various HTTP response codes, HTTP 500 errors, and log errors for greater operational insight
* **Violations** - This dashboard provides an aggregated summary of all the license violations and security vulnerabilities found by Xray.  Information is segment by watch policies and rules.  Trending information is provided on the type and severity of violations over time, as well as, insights on most frequently occurring CVEs, top impacted artifacts and components
* **Metrics** - To gain insights into the system performance, storage consumption, connection statistics, count and type of artifacts and components scanned by JFrog Xray

## Demo Requirements

* Kubernetes Cluster
* Artifactory and/or Xray installed via [JFrog Helm Charts](https://github.com/jfrog/charts)
* Helm 3
* New Relic account setup with license key

## Generating Data for Testing

[Partner Integration Test Framework](https://github.com/jfrog/partner-integration-tests) can be used to generate data for metrics

## References

* [New Relic](https://one.newrelic.com/) - New Relic Platform
* [New Relic Fluentd plugin](https://docs.newrelic.com/docs/logs/forward-logs/fluentd-plugin-log-forwarding/) - Fluentd output plugin for sending data to New Relic

