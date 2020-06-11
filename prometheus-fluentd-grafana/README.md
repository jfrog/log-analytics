# Artifactory and Xray Logging Analytics with FluentD, Prometheus and Grafana
The following describes how to configure Prometheus and Grafana to gather metrics from Artifactory and Xray through the use of FluentD. The setup and configuration of Prometheus and Grafana uses Kubernetes and makes use of the Prometheus Operator.

## Requirements
* Kubernetes Cluster
* Artifactory and/or Xray installed via [JFrog Helm Charts](https://github.com/jfrog/charts)
* Helm 3

## Installing Prometheus and Grafana (via Operator) on K8s
The [Prometheus Operator](https://coreos.com/operators/prometheus/docs/latest/) allows the creation of Prometheus instances and includes Grafana. Install the Prometheus Operator via Helm:

```
helm install jfrog-prometheus stable/prometheus-operator
```

## FluentD Configuration
The following steps describe how to configure FluentD to gather metrics for Prometheus. Refer to the main [README](../README.md) for more details.
1. Install the [FluentD Prometheus Plugin](https://github.com/fluent/fluent-plugin-prometheus).
2. Use the appropriate FluentD configuration file (*.prometheus) and copy it to /etc/td-agent/td-agent.conf.
3. Restart td-agent.
4. In order to expose the /metrics interface for Prometheus to scrape, apply the appropriate *-metrics-service.yaml.

```
eg.
kubectl apply -f artifactory-ha-member-metrics-service.yaml
```
5. The /metrics interface is now available at http://<service>:24231/metrics
![metrics](images/metrics.png)

## Configuring Prometheus to Gather Metrics from Artifactory and Xray on K8s
The following steps using the Prometheus Operator to create a Prometheus instance and the ServiceMonitor to gather metrics. The [ServiceMonitor](https://coreos.com/operators/prometheus/docs/latest/user-guides/running-exporters.html) resource tells Prometheus where the metrics service. This metrics service provides the metrics data for the Prometheus "scrapes".
1. Create a new Prometheus instance.
```
kubectl apply -f prometheus-jfrog.yaml
```
2. Apply the RBAC manifest to allow Prometheus to monitor for new ServiceMonitors.
```
kubectl apply -f prometheus-rbac.yaml
```
3. Create the appropriate ServiceMonitor to gather metrics.
```
kubectl apply -f servicemonitor-*.yaml

eg.
kubectl apply -f servicemonitor-artifactory-ha-member.yaml
```
4. Go to the web ui of the Prometheus instance create in Step 1 and verify the Targets list shows the new ServiceMonitor.
![targets](images/targets.png)

5. Finally, go to Grafana to add your Prometheus instance as a datasource.
![datasource](images/datasource.png)

## Exposing Prometheus, Grafana and FluentD Metrics Interface for Testing
For testing purposes, you may want to expose Prometheus, Grafana and the FluentD Metrics interface. A test-only-expose.yaml provides an example of how to do this:
```
kubectl apply -f test-only-expose.yaml
```
## Grafana Dashboard
An example dashboard is included in the [grafana directory](./grafana).
![datasource](images/dashboard.png)

## Generating Data for Testing
[Partner Integration Test Framework](https://github.com/jfrog/partner-integration-tests) can be used to generate data for metrics.

## References
* [FluentD Plugin for Prometheus Metrics](https://github.com/fluent/fluent-plugin-prometheus#supported-metric-types)
* [Grafana Dashboards](https://grafana.com/docs/grafana/latest/features/dashboard/dashboards/)
* [Grafana Queries](https://prometheus.io/docs/prometheus/latest/querying/basics/)