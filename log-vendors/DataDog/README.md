# DataDog Integration

## Versions Supported

This integration is last tested with Artifactory 7.77.11 and Xray 3.88.12 versions.

## DataDog Setup

Datadog setup can be done by going through the below onboarding steps or by using apiKey directly if one exists. If an apiKey exists, skip the steps below and move on to [Fluentd Installation](#fluentd-installation) to forward logs directly to your datadog account.

* Create an account in Datadog
* Run the datadog agent in your kubernetes cluster by deploying it with a helm chart
* To enable log collection, update datadog-values.yaml file given in the onboarding steps of datadog
* Once the agent starts reporting, you'll get an apiKey which we'll be using to send formatted logs through fluentd

Once datadog is setup, we can access logs via Logs > Search. We can also select the specific source that we want to get logs from. Adding proper metadata is the key to unlocking the full potential of your logs in datadog. By default, the hostname and timestamp fields should be remapped.

* Add all attributes as facets from Facets > Add on the left side of the screen in Logs > search
