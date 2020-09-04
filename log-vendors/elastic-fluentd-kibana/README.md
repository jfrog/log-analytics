# Artifactory and Xray Logging Analytics with FluentD, ElasticSearch and Kibana

The following describes how to configure Elastic and Kibana to gather metrics from Artifactory and Xray through the use of FluentD.


| version | artifactory | xray  | distribution | mission_control | pipelines |
|---------|-------------|-------|--------------|-----------------|-----------|
| 0.4.0   | 7.7.3       | 3.8.0 | 2.4.2        | 4.5.0           | N/A       |
| 0.3.0   | 7.7.3       | 3.8.0 | 2.4.2        | N/A             | N/A       |
| 0.2.0   | 7.7.3       | 3.8.0 | N/A          | N/A             | N/A       |
| 0.1.1   | 7.6.3       | 3.6.2 | N/A          | N/A             | N/A       |
## Requirements

* Kubernetes Cluster
* Artifactory and/or Xray installed via [JFrog Helm Charts](https://github.com/jfrog/charts)
* Helm 3

## Installing Elasticsearch and Kibana on K8s

Elasticsearch kibana setup can be done using the following files or using manual configuration

* [Elastic_configmap](https://github.com/jfrog/log-analytics/blob/master/elastic-fluentd-kibana/elasticsearch_configmap.yaml) - Elasticsearch ConfigMap
* [Elastic_statefulset](https://github.com/jfrog/log-analytics/blob/master/elastic-fluentd-kibana/elasticsearch_statefulset.yaml) - Elasticsearch Statefulset
* [Elastic_service](https://github.com/jfrog/log-analytics/blob/master/elastic-fluentd-kibana/elasticsearch_svc.yaml) - Elasticsearch Service
* [Kibana_configmap](https://github.com/jfrog/log-analytics/blob/master/elastic-fluentd-kibana/kibana_configmap.yaml) - Kibana ConfigMap
* [Kibana_deployment](https://github.com/jfrog/log-analytics/blob/master/elastic-fluentd-kibana/kibana_deployment.yaml) - Kibana Deplpoyment
* [Kibana_service](https://github.com/jfrog/log-analytics/blob/master/elastic-fluentd-kibana/kibana_svc.yaml) - Kibana Service

Once we have deployed elasticsearch and kibana, we can access it via kibana web console. We can check for the running logging agents in Index Management section

## FluentD Configuration

Integration is done by specifying the host (elasticsearch - using the above files or ip address if using other coniguration), port (9200 by default)

_index_name_ is the unique identifier based on which the index patterns can be created and filters can be applied on the log data

When _logstash_format_ option is set to true, fluentd uses conventional index name format

_type_name_ is fluentd by default and it specifies the type name to write to in the record and falls back to the default if a value is not given

_include_tag_key_ defaults to false and it will add fluentd tag in the json record if set to true

_user_ will be elastic by default

_password_ will be the password specified for elastic user in elasticsearch authentication setup

```
<match jfrog.**>
  @type elasticsearch
  @id elasticsearch
  host elasticsearch
  port 9200
  user "elastic"
  password <password>
  index_name unified-artifactory
  include_tag_key true
  type_name fluentd
  logstash_format false
</match>
```

## EFK Demo

To run this integration start by creating elasticsearch configmap, service and statefulset

``` 
kubectl create -f elasticsearch_configmap.yaml
kubectl create -f elasticsearch_svc.yaml
kubectl create -f elasticsearch_statefulset.yaml
```

Check for the status of the statefulset using

```
kubectl rollout status sts/es-cluster
```

Setup passwords for elasticsearch using

```
kubectl exec -it $(kubectl get pods | grep es-cluster-0 | sed -n 1p | awk '{print $1}') -- bin/elasticsearch-setup-passwords interactive
```
Note the password given to elastic user

Create Kibana configmap, service and deployment

```
kubectl create -f kibana_configmap.yaml
kubectl create -f kibana_svc.yaml
kubectl create -f kibana_deployment.yaml
```

Wait for the deployment status using

```
kubectl rollout status deployment/kibana
```

This will create a Kibana web console which can be used using username as elastic and password as specified in the interactive authentication setup

Once the kibana is up, the host and port should be configured in td-agent.conf and td-agent can be started. This creates an index with the name specified in the conf file

Creat an index pattern in the Management section and access the logs on the discover tab

To access already existing visualizations and filters, import [export.ndjson](https://github.com/jfrog/log-analytics/blob/master/elastic-fluentd-kibana/export.ndjson) to Saved objects in Management section

## Generating Data for Testing
[Partner Integration Test Framework](https://github.com/jfrog/partner-integration-tests) can be used to generate data for metrics.

## References
* [Elasticsearch](https://www.elastic.co/) - Elastic search log data platform
* [Kibana](https://www.elastic.co/kibana) - Elastic search visualization layer