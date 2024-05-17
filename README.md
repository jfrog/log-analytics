# JFrog Log Analytics Integrations

The following document describes how to configure Datadog, Splunk and New Relic to gather logs, metrics and violations from Artifactory and Xray through the use of FluentD.

## Observability Vendors Supported

The following observability vendors are supported in this repository:

* DataDog
* Splunk
* New Relic

Other observability solutions are supported. For Prometheus-Loki-Grafana log analytics integration please [visit here](https://github.com/jfrog/log-analytics-prometheus)

## Version Supported

The following Artifactory and Xray versions are supported in this repository:

* Artifactory: 7.77.11
* Xray: 3.88.12

## Table of Contents

1. [Integration Specific Setup](#integration-specific-setup)
2. [JFrog Metrics Setup](#jfrog-metrics-setup)
3. [Fluentd Installation](#fluentd-installation)

   * [OS / Virtual Machine](#os--virtual-machine)
   * [Docker](#docker)
   * [Kubernetes Deployment with Helm](#kubernetes-deployment-with-helm)
4. [Dashboards](#dashboards)
5. [References](#references)

## Integration Specific Setup

Before we begin the installation please refer to your observability provider section for a needed setup which is unique to your integration:

* For **Splunk** integration please follow the following steps [here](log-vendors/Splunk#splunk-setup)
* For **DataDog** integration please follow the following steps [here](log-vendors/DataDog/#datadog-setup)
* For **New Relic** integration please follow the following steps [here](log-vendors/NewRelic/#new-relic-setup)

After completing the vendor specific setup phase, please continue to the following steps below

## JFrog Metrics Setup

To enable metrics in Artifactory, make the following configuration changes to the [Artifactory System YAML](https://www.jfrog.com/confluence/display/JFROG/Artifactory+System+YAML)

```yaml
span
```

Once this configuration is done and the application is restarted, metrics will be available in Open Metrics Format

Metrics are enabled by default in Xray.
For kubernetes based installs, openMetrics are enabled in the helm install commands listed below

## Fluentd Installation

### OS / Virtual Machine

Ensure you have access to the Internet from VM. Recommended install is through fluentd's native OS based package installs:


| OS            | Package Manager     | Link                                                 |
| ------------- | ------------------- | ---------------------------------------------------- |
| CentOS/RHEL   | Linux - RPM (YUM)   | https://docs.fluentd.org/installation/install-by-rpm |
| Debian/Ubuntu | Linux - APT         | https://docs.fluentd.org/installation/install-by-deb |
| MacOS/Darwin  | MacOS - DMG         | https://docs.fluentd.org/installation/install-by-dmg |
| Windows       | Windows - MSI       | https://docs.fluentd.org/installation/install-by-msi |
| Gem Install** | MacOS & Linux - Gem | https://docs.fluentd.org/installation/install-by-gem |

#### Install Ruby (Gem-based installations)
For Gem based install, Ruby Interpreter has to be setup first, following is the recommended process to install Ruby:

1. Install Ruby Version Manager (RVM) as described in https://rvm.io/rvm/install#installation-explained, ensure to follow all the onscreen instructions provided to complete the rvm installation
	* For installation across users a SUDO based install is recommended, the installation is as described in https://rvm.io/support/troubleshooting#sudo

2. Once rvm installation is complete, verify the RVM installation executing the command 'rvm -v'

3. Now install ruby v2.7.0 or above executing the command `rvm install <ver_num>`, ex: `rvm install 2.7.5`

4. Verify the ruby installation, execute the following commands to ensure all the components are intact:
   ```bash
   # verify ruby installation
   ruby -v 
   # verify gems installation
   gem -v
   bundler -v
   ```

#### Install FluentD
Post completion of Ruby, Gems installation, the environment is ready to further install new gems, execute the following gem install commands one after other to setup the needed ecosystem

```bash
gem install fluentd
```
#### Install FluentD plugins
After FluentD is successfully installed, the below plugins are required to be installed

<details><summary>Install FluentD plugins for Splunk</summary>

```bash
gem install fluent-plugin-concat
gem install fluent-plugin-jfrog-siem
gem install fluent-plugin-jfrog-metrics
gem install fluent-plugin-splunk-hec
```
</details>
<details><summary>Install FluentD plugins for DataDog</summary>

```bash
gem install fluent-plugin-concat
gem install fluent-plugin-jfrog-siem
gem install fluent-plugin-jfrog-metrics
gem install fluent-plugin-datadog
gem install fluent-plugin-jfrog-send-metrics
```
</details>

<details><summary>Install FluentD plugins for New Relic</summary>

```bash
gem install fluent-plugin-concat
gem install fluent-plugin-jfrog-siem
gem install fluent-plugin-jfrog-metrics
gem install fluent-plugin-newrelic
gem install fluent-plugin-jfrog-send-metrics
```
</details>

#### Configure Fluentd

We rely heavily on environment variables so that the correct log files are streamed to your observability dashboards. Ensure that you fill in the .env file with correct values.

Configure the environment variables with accordance to your observability provider:

<details><summary> Configure Splunk </summary>

Download the .env file from [here](./log-vendors/Splunk/jfrog.env)

<ul>
   <li><b>SPLUNK_COM_PROTOCOL</b>: HTTP Scheme, http or https</li>
   <li><b>SPLUNK_HEC_HOST</b>: Splunk Instance URL</li>
   <li><b>SPLUNK_HEC_PORT</b>: Splunk HEC configured port</li>
   <li><b>SPLUNK_HEC_TOKEN</b>: Splunk HEC Token for sending logs to Splunk</li>
   <li><b>SPLUNK_METRICS_HEC_TOKEN</b>: Splunk HEC Token for sending metrics to Splunk</li>
   <li><b>SPLUNK_INSECURE_SSL</b>: false for test environments only or if http scheme</li>
   <li><b>JF_PRODUCT_DATA_INTERNAL</b>: The environment variable JF_PRODUCT_DATA_INTERNAL must be defined to the correct location. For each JFrog service you will find its active log files in the `$JFROG_HOME/<product>/var/log` directory</li>
   <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
   <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
   <li><b>JFROG_ADMIN_TOKEN</b>: Artifactory <a href="https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory">Access Token</a> for authentication</li>
   <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
</ul>
Run the following command/s to generate the `fluentd.conf.rt` or `fluentd.conf.xray` file for the steps below:

```bash
cat fluentd-conf/fluentd.conf.shared.rt log-vendors/Splunk/fluend-conf/fluentd.conf.rt > fluentd.conf.rt
```

OR

```bash
cat fluentd-conf/fluentd.conf.shared.xray log-vendors/Splunk/fluend-conf/fluentd.conf.xray >  fluentd.conf.xray
```

In order to verify that your environment variables are set correctly, run the following commands:

```bash
   env_vars=("SPLUNK_COM_PROTOCOL" "SPLUNK_HEC_HOST" "SPLUNK_HEC_PORT" "SPLUNK_HEC_TOKEN" "SPLUNK_METRICS_HEC_TOKEN" "SPLUNK_INSECURE_SSL" "JF_PRODUCT_DATA_INTERNAL" "JPD_URL" "JPD_ADMIN_USERNAME" "JFROG_ADMIN_TOKEN" "COMMON_JPD")
   ./test_envs.sh $env_vars
```

</details>
<details><summary>Configure DataDog</summary>

Download the .env file from [here](log-vendors/DataDog/jfrog.env)

<ul>
   <li><b>DATADOG_API_KEY</b>: API Key from <a href="https://app.datadoghq.com/organization-settings/api-keys">Datadog</a></li>
   <li><b>DATADOG_API_HOST</b>: Your DataDog host based on your <a href="https://docs.datadoghq.com/getting_started/site/#access-the-datadog-site">DataDog Site Parameter from this list</a></li>
   <li><b>JF_PRODUCT_DATA_INTERNAL</b>: The environment variable JF_PRODUCT_DATA_INTERNAL must be defined to the correct location. For each JFrog service, you can find its active log files in the `$JFROG_HOME/<product>/var/log` directory</li>
   <li><b>JPD_URL</b>: Artifactory JPD URL with the format `http://<ip_address>`</li>
   <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
   <li><b>JFROG_ADMIN_TOKEN</b>: Artifactory <a href="https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory">Access Token</a> for authentication</li>
   <li><b>COMMON_JPD</b>: This flag should be set as true only for non-Kubernetes installations or installations where the JPD base URL is the same to access both Artifactory and Xray (for example, `https://sample_base_url/artifactory` or `https://sample_base_url/xray`)</li>
</ul>
Run the following command/s to generate the `fluentd.conf.rt` or `fluentd.conf.xray` file for the steps below:

```bash
cat fluentd-conf/fluentd.conf.shared.rt log-vendors/DataDog/fluend-conf/fluentd.conf.rt > fluentd.conf.rt
```

OR

```bash
 cat fluentd-conf/fluentd.conf.shared.xray log-vendors/DataDog/fluend-conf/fluentd.conf.xray > fluentd.conf.xray
```

In order to verify that your environment variables are set correctly, run the following commands:

```bash
   env_vars=("DATADOG_API_KEY" "DATADOG_API_HOST" "JF_PRODUCT_DATA_INTERNAL" "JPD_URL" "JPD_ADMIN_USERNAME" "JFROG_ADMIN_TOKEN" "COMMON_JPD")
   ./test_envs.sh $env_vars
```

</details>

<details><summary>Configure New Relic</summary>

Download the .env file [here](log-vendors/NewRelic/jfrog.env)

<ul>
   <li><b>NEWRELIC_LICENSE_KEY</b>: License Key from <a href="https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher">NewRelic</a></li>
   <li><b>NEWRELIC_LOGS_URI</b>: This New Relic logs endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://log-api.newrelic.com/log/v1</li>
   <li><b>NEWRELIC_METRICS_URI</b>: This New Relic metrics endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://metric-api.newrelic.com/metric/v1</li>
   <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
   <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
   <li><b>JPD_ADMIN_TOKEN</b>: Artifactory <a href="https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory">Access Token</a> for authentication
   <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
</ul>

Run the following command/s to generate the `fluentd.conf.rt` or `fluentd.conf.xray` file for the steps below:

```bash
cat fluentd-conf/fluentd.conf.shared.rt log-vendors/NewRelic/fluentd-conf/fluentd.conf.rt > fluentd.conf.rt
```

OR

```bash
cat fluentd-conf/fluentd.conf.shared.xray log-vendors/NewRelic/fluentd-conf/fluentd.conf.xray > fluentd.conf.xray
```

</details><br>

Apply the `.env` files and run the fluentd wrapper with the following command, and note that the argument points to the `fluent.conf.*` file previously configured:

```bash
source jfrog.env
./fluentd $JF_PRODUCT_DATA_INTERNAL/fluent.conf.<product_name>
```

In order to verify that your environment variables are set correctly, run the following commands:

```bash
env_vars=("NEWRELIC_LICENSE_KEY" "NEWRELIC_LOGS_URI" "NEWRELIC_METRICS_URI" "JF_PRODUCT_DATA_INTERNAL" "JPD_URL" "JPD_ADMIN_USERNAME" "JPD_ADMIN_TOKEN" "COMMON_JPD")
./test_envs.sh $env_vars
```

### Docker

`Note! These steps were not tested to work out of the box on MAC`
In order to run fluentd as a docker image to send the logs, violations and metrics data to your observability provider, the following commands needs to be executed on the host that runs the docker.

#### Download required docker files for the setup
1. Check the docker installation is functional, execute commands

```bash
docker version
docker ps
```
2. Once the version and process are listed successfully, build the intended docker image using the docker file
   * Download `Dockerfile` to any directory which has write permissions:<br>
     [Dockerfile](docker-build/Dockerfile)<br>

3. Download the `docker.env` file needed to run Jfrog/FluentD docker images for your integration:
   * Download `docker.env` to the directory where the `Dockerfile` was downloaded:<br>
     [Splunk docker.env](log-vendors/Splunk/docker/docker.env)<br>
     [DataDog docker.env](log-vendors/DataDog/docker/docker.env)<br>
     [New Relic docker.env](log-vendors/NewRelic/docker/docker.env)<br>

#### Docker Container Setup
Execute the following commands to setup the docker container running the FluentD installation

1. Execute the following command to build the docker image:

   <details><summary>For Splunk</summary>
   Run the following command to generate the <b>fluentd.conf.rt</b> or <b>fluentd.conf.xray</b> file for the steps below:

   ```bash
   cat fluentd-conf/fluentd.conf.shared.rt log-vendors/Splunk/fluentd-conf/fluentd.conf.rt > fluentd.conf.rt
   ```
   OR
   ```bash
   cat fluentd-conf/fluentd.conf.shared.xray log-vendors/Splunk/fluentd-conf/fluentd.conf.xray > fluentd.conf.xray
   ```
   Build a docker image ,using the above generated FluentD config file (for Artifactory or Xray)    
   ```bash
   docker build --build-arg TARGET="SPLUNK" --build-arg FLUENTD_CONF_LOCATION=<fluentd_conf__file_location> -f <docker_file_location> -t <image_name> .
   ```

   Command examples

   ```bash
   docker build --build-arg TARGET="SPLUNK" --build-arg FLUENTD_CONF_LOCATION="./fluentd.conf.rt" -f ./docker-build/Dockerfile -t jfrog/fluentd-splunk-rt .
   docker build --build-arg TARGET="SPLUNK" --build-arg FLUENTD_CONF_LOCATION="./fluentd.conf.xray" -f ./docker-build/Dockerfile -t jfrog/fluentd-splunk-xray .
   ```
   </details>
   <details><summary>For DataDog</summary>
   Run the following command to generate the <b>fluentd.conf.rt</b> or <b>fluentd.conf.xray</b> file for the steps below:

   ```bash
   cat fluentd-conf/fluentd.conf.shared.rt log-vendors/DataDog/fluentd-conf/fluentd.conf.rt > fluentd.conf.rt
   ```
   OR
   ```bash
   cat fluentd-conf/fluentd.conf.shared.xray log-vendors/DataDog/fluentd-conf/fluentd.conf.xray > fluentd.conf.xray
   ```
   Build a docker image ,using the above generated FluentD config file (for Artifactory or Xray)    
   ```bash
   docker build --build-arg TARGET="DATADOG" --build-arg FLUENTD_CONF_LOCATION=<fluentd_conf__file_location> -f <docker_file_location> -t <image_name> .
   ```

   Command examples

   ```bash
   docker build --build-arg TARGET="DATADOG" --build-arg FLUENTD_CONF_LOCATION="./fluentd.conf.rt" -f ./docker-build/Dockerfile -t jfrog/fluentd-datadog-rt .
   docker build --build-arg TARGET="DATADOG" --build-arg FLUENTD_CONF_LOCATION="./fluentd.conf.xray" -f ./docker-build/Dockerfile -t jfrog/fluentd-datadog-xray .
   ```
   </details>
   <details><summary>For New Relic</summary>
   Run the following command to generate the <b>fluentd.conf.rt</b> or <b>fluentd.conf.xray</b> file for the steps below:

   ```bash
   cat fluentd-conf/fluentd.conf.shared.rt log-vendors/NewRelic/fluentd-conf/fluentd.conf.rt > fluentd.conf.rt
   ```
   OR
   ```bash
   cat fluentd-conf/fluentd.conf.shared.xray log-vendors/NewRelic/fluentd-conf/fluentd.conf.xray > fluentd.conf.xray
   ```
   Build a docker image ,using the above generated FluentD config file (for Artifactory or Xray)    
   ```bash
   docker build --build-arg TARGET="NEWRELIC" --build-arg FLUENTD_CONF_LOCATION=<fluentd_conf__file_location> -f <docker_file_location> -t <image_name> .
   ```

   Command examples

   ```bash
   docker build --build-arg TARGET="NEWRELIC" --build-arg FLUENTD_CONF_LOCATION="./fluentd.conf.rt" -f ./docker-build/Dockerfile -t jfrog/fluentd-newrelic-rt .
   docker build --build-arg TARGET="NEWRELIC" --build-arg FLUENTD_CONF_LOCATION="./fluentd.conf.xray" -f ./docker-build/Dockerfile -t jfrog/fluentd-newrelic-xray .
   ```  
   </details><br>

2. Fill the necessary information in the docker.env file:

   Please fill the environment variables values with accordance to your specific integration:

   <details><summary>Splunk environment variables configuration</summary>
   Download the .env file from [here](log-vendors/Splunk/docker/docker.env). Fill in the docker.env file with correct values:
   <ul>
      <li><b>SPLUNK_COM_PROTOCOL</b>: HTTP Scheme, http or https</li>
      <li><b>SPLUNK_HEC_HOST</b>: Splunk Instance URL</li>
      <li><b>SPLUNK_HEC_PORT</b>: Splunk HEC configured port</li>
      <li><b>SPLUNK_HEC_TOKEN</b>: Splunk HEC Token for sending logs to Splunk</li>
      <li><b>SPLUNK_METRICS_HEC_TOKEN</b>: Splunk HEC Token for sending metrics to Splunk</li>
      <li><b>SPLUNK_INSECURE_SSL</b>: false for test environments only or if http scheme</li>
      <li><b>JF_PRODUCT_DATA_INTERNAL</b>: The environment variable JF_PRODUCT_DATA_INTERNAL must be defined to the correct location. For each JFrog service you will find its active log files in the `$JFROG_HOME/<product>/var/log` directory</li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>JFROG_ADMIN_TOKEN*</b>: Artifactory <a href="https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory">Access Token</a> for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>

   In order to verify that your environment variables are set correctly, run the following commands:

   ```bash
      env_vars=("SPLUNK_COM_PROTOCOL" "SPLUNK_HEC_HOST" "SPLUNK_HEC_PORT" "SPLUNK_HEC_TOKEN" "SPLUNK_METRICS_HEC_TOKEN" "SPLUNK_INSECURE_SSL" "JF_PRODUCT_DATA_INTERNAL" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```

   </details>

   <details><summary>DataDog environment variables configuration</summary>
   Download the .env file from [here](log-vendors/DataDog/docker/docker.env). Fill in the docker.env file with correct values:
   <ul>
      <li><b>DATADOG_API_KEY</b>: API Key from <a href="https://docs.datadoghq.com/account_management/api-app-keys/">here</a></li>
      <li><b>DATADOG_API_HOST</b>: Your DataDog host based on your <a href="https://docs.datadoghq.com/getting_started/site/#access-the-datadog-site">DataDog Site Parameter from this list</a></li>
      <li><b>JF_PRODUCT_DATA_INTERNAL</b>: The environment variable JF_PRODUCT_DATA_INTERNAL must be defined to the correct location. For each JFrog service you will find its active log files in the `$JFROG_HOME/<product>/var/log` directory</li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>JFROG_ADMIN_TOKEN*</b>: Artifactory <a href="https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory">Access Token</a> for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>

   In order to verify that your environment variables are set correctly, run the following commands:

   ```bash
      env_vars=("DATADOG_API_KEY" "DATADOG_API_HOST" "JF_PRODUCT_DATA_INTERNAL" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```

   </details>

   <details><summary>New Relic environment variables configuration</summary>
   Download the .env file from [here](log-vendors/NewRelic/docker/docker.env). Fill in the docker.env file with correct values:
   <ul>
      <li><b>NEWRELIC_LICENSE_KEY</b>: License Key from <a href="https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher">NewRelic</a></li>
      <li><b>NEWRELIC_LOGS_URI</b>: This New Relic logs endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://log-api.newrelic.com/log/v1</li>
      <li><b>NEWRELIC_METRICS_URI</b>: This New Relic metrics endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://metric-api.newrelic.com/metric/</li>
      <li><b>JF_PRODUCT_DATA_INTERNAL</b>: The environment variable JF_PRODUCT_DATA_INTERNAL must be defined to the correct location. For each JFrog service you will find its active log files in the `$JFROG_HOME/<product>/var/log` directory</li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>JFROG_ADMIN_TOKEN*</b>: Artifactory <a href="https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory">Access Token</a> for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>

   In order to verify that your environment variables are set correctly, run the following commands:

   ```bash
     env_vars=("NEWRELIC_LICENSE_KEY" "NEWRELIC_LOGS_URI" "NEWRELIC_METRICS_URI" "JF_PRODUCT_DATA_INTERNAL" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
     ./test_envs.sh $env_vars
   ```

   </details>
3. Execute the following command:

   ```bash
   docker run -it --name jfrog-fluentd-rt -v <path_to_logs>:/var/opt/jfrog/artifactory --env-file docker.env <image_name>
   ```

   The <path_to_logs> should be an absolute path where the Jfrog Artifactory Logs folder resides, i.e for an Docker based Artifactory Installation,  ex: /var/opt/jfrog/artifactory/var/logs on the docker host.

   Command example:

   ```bash
      docker run -it --name jfrog-fluentd-rt -v $JFROG_HOME/artifactory/var/:/var/opt/jfrog/artifactory --env-file docker.env jfrog/fluentd-rt
   ```

### Kubernetes Deployment with Helm

Recommended installation for Kubernetes is to utilize the [JFrog helm charts](https://github.com/jfrog/charts) with the associated values.yaml in this repo:


| Product                       | Purpose                |    Example Values File                                  |
| ----------------------------- | ---------------------- | ------------------------------------------------------- |
| Artifactory OR Artifactory HA | shared values          | helm/artifactory-shared-values.yaml                     |
| Artifactory OR Artifactory HA | vendor specific values | log-vendors/\<log-vendor\>/helm/artifactory-values.yaml |
| Xray                          | shared values          | helm/xray-shared-values.yaml                            |
| Xray                          | vendor specific values | log-vendors/\<log-vendor\>/helm/xray-values.yaml        |

Add JFrog Helm repository:

```bash
helm repo add jfrog https://charts.jfrog.io
helm repo update
```

Throughout the exampled helm installations we'll use `jfrog-int` as an example namespace. That said, you can use a different or existing namespace instead by setting the following environment variable

```bash
export INST_NAMESPACE=jfrog-int
```

If you don't have an existing namespace for the deployment, create it and set the kubectl context to use this namespace

```bash
kubectl create namespace $INST_NAMESPACE
kubectl config set-context --current --namespace=$INST_NAMESPACE
```

Replace placeholders with your ``masterKey`` and ``joinKey``. To generate each of them, use the command
``openssl rand -hex 32``

```bash
export JOIN_KEY=$(openssl rand -hex 32)
export MASTER_KEY=$(openssl rand -hex 32)
```

Optional: Create a kubernetes secret with Artifactory/Platform license key
```bash
kubectl create secret generic artifactory-license --from-file=<path_to_license_file>

# for example with a file named art.lic in this dir (which contains the Artifactory license)
kubectl create secret generic artifactory-license --from-file=./art.lic
```
if you decided to create this license secret please uncomment the license section in the [artifactory values yaml](helm/artifactory-shared-values.yaml).
For more information regarding loading an Artifactory license from a secret please visit the [official JFrog user docs](https://jfrog.com/help/r/jfrog-installation-setup-documentation/add-licenses-with-artifactory-ha-helm-installation)


#### Artifactory ⎈:

1. Skip this step if you already have Artifactory installed. Else, install Artifactory using the command below

   ```bash
   helm upgrade --install artifactory  jfrog/artifactory \
      --set artifactory.masterKey=$MASTER_KEY \
      --set artifactory.joinKey=$JOIN_KEY \
      -n $INST_NAMESPACE
   ```
2. Once Artifactory installation was completed successfully, create a secret for JFrog's admin token - [Access Token](https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory) using any of the following methods

   ```bash
   kubectl create secret generic jfrog-admin-token --from-file=token=<path_to_token_file>

   OR

   kubectl create secret generic jfrog-admin-token --from-literal=token=<JFROG_ADMN_TOKEN>
   ```
3. For Artifactory installation, download the .env file from:

   <details><summary>Set environment variables for the Splunk integration</summary>

   Download the .env file from [here](log-vendors/Splunk/helm/jfrog_helm.env). Fill in the jfrog_helm.env file with correct values:

   <ul>
      <li><b>SPLUNK_COM_PROTOCOL</b>: HTTP Scheme, http or https</li>
      <li><b>SPLUNK_HEC_HOST</b>: Splunk Instance URL</li>
      <li><b>SPLUNK_HEC_PORT</b>: Splunk HEC configured port</li>
      <li><b>SPLUNK_HEC_TOKEN</b>: Splunk HEC Token for sending logs to Splunk</li>
      <li><b>SPLUNK_METRICS_HEC_TOKEN</b>: Splunk HEC Token for sending metrics to Splunk</li>
      <li><b>SPLUNK_INSECURE_SSL</b>: false for test environments only or if http scheme</li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>
   Apply the .env file that you created in the previous step, using the command below

   ```bash
   source jfrog_helm.env
   ```

   In order to verify that your environment variables are set correctly, run the following commands::

   ```bash
      env_vars=("SPLUNK_COM_PROTOCOL" "SPLUNK_HEC_HOST" "SPLUNK_HEC_PORT" "SPLUNK_HEC_TOKEN" "SPLUNK_METRICS_HEC_TOKEN" "SPLUNK_INSECURE_SSL" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```

   </details>
   <details><summary>Set environment variables for the DataDog integration</summary>

   Download the .env file from [here](log-vendors/DataDog/helm/jfrog_helm.env). Fill in the jfrog_helm.env file with correct values:

   <ul>
      <li><b>DATADOG_API_KEY</b>: API Key from <a href="https://app.datadoghq.com/organization-settings/api-keys">Datadog</a></li>
      <li><b>DATADOG_API_HOST</b>: Your DataDog host based on your <a href="https://docs.datadoghq.com/getting_started/site/#access-the-datadog-site">DataDog Site Parameter from this list</a></li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-Kubernetes installations or installations where the JPD base URL is the same to access both Artifactory and Xray (for example, `https://sample_base_url/artifactory` or `https://sample_base_url/xray`)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>
   Apply the .env file that you created in the previous step, using the command below

   ```bash
   source jfrog_helm.env
   ```

   In order to verify that your environment variables are set correctly, run the following commands:

   ```bash
      env_vars=("DATADOG_API_KEY" "DATADOG_API_HOST" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```

   </details>
   <details><summary>Set environment variables for the New Relic integration</summary>

   Download the .env file from [here](log-vendors/NewRelic/helm/jfrog_helm.env). Fill in the jfrog_helm.env file with correct values:

   <ul>
      <li><b>NEWRELIC_LICENSE_KEY</b>: License Key from <a href="https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher">NewRelic</a></li>
      <li><b>NEWRELIC_LOGS_URI</b>: This New Relic logs endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://log-api.newrelic.com/log/v1 if isn't set</li>
      <li><b>NEWRELIC_METRICS_URI</b>: This New Relic metrics endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://metric-api.newrelic.com/metric/v1 if isn't set</li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>

   Apply the .env file that you created in the previous step, using the command below

   ```bash
   source jfrog_helm.env
   ```

   In order to verify that your environment variables are set correctly, run the following commands:

   ```bash
      env_vars=("NEWRELIC_LICENSE_KEY" "NEWRELIC_LOGS_URI" "NEWRELIC_METRICS_URI" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```

   </details>
4. Postgres password is required to upgrade Artifactory. Run the following command to get the current password

   ```bash
   POSTGRES_PASSWORD=$(kubectl get secret artifactory-postgresql -n $INST_NAMESPACE -o jsonpath="{.data.postgresql-password}" | base64 --decode)
   ```
5. Upgrade Artifactory installation using the command below:

   <details><summary>Upgrade Artifactory with Splunk integration</summary>

   ```bash
   helm upgrade --install artifactory jfrog/artifactory --set artifactory.jfrogUrl=$JPD_URL \
      --set artifactory.joinKey=$JOIN_KEY \
      --set postgresql.postgresqlPassword=$POSTGRES_PASSWORD \
      --set splunk.host=$SPLUNK_HEC_HOST \
      --set splunk.port=$SPLUNK_HEC_PORT \
      --set splunk.logs_token=$SPLUNK_HEC_TOKEN \
      --set splunk.metrics_token=$SPLUNK_METRICS_HEC_TOKEN \
      --set splunk.insecure_ssl=$SPLUNK_INSECURE_SSL \
      --set splunk.com_protocol=$SPLUNK_COM_PROTOCOL \
      --set jfrog.observability.jpd_url=$JPD_URL \
      --set jfrog.observability.username=$JPD_ADMIN_USERNAME \
      --set jfrog.observability.common_jpd=$COMMON_JPD \
      -f log-vendors/Splunk/helm/artifactory-values.yaml -f helm/artifactory-shared-values.yaml \
      -n $INST_NAMESPACE
   ```

   </details>
   <details><summary>Upgrade Artifactory with DataDog integration</summary>

   ```bash
   helm upgrade --install artifactory jfrog/artifactory --set artifactory.jfrogUrl=$JPD_URL \
      --set artifactory.joinKey=$JOIN_KEY \
      --set postgresql.postgresqlPassword=$POSTGRES_PASSWORD \
      --set datadog.api_key=$DATADOG_API_KEY \
      --set datadog.api_host=$DATADOG_API_HOST \
      --set jfrog.observability.jpd_url=$JPD_URL \
      --set jfrog.observability.username=$JPD_ADMIN_USERNAME \
      --set jfrog.observability.common_jpd=$COMMON_JPD \
      -f log-vendors/DataDog/helm/artifactory-values.yaml -f helm/artifactory-shared-values.yaml \
      -n $INST_NAMESPACE
   ```

   </details>
   <details><summary>Upgrade Artifactory with New Relic integration</summary>

   ```bash
   helm upgrade --install artifactory jfrog/artifactory --set artifactory.jfrogUrl=$JPD_URL \
      --set artifactory.joinKey=$JOIN_KEY \
      --set postgresql.postgresqlPassword=$POSTGRES_PASSWORD \
      --set newrelic.license_key=$NEWRELIC_LICENSE_KEY \
      --set newrelic.logs_uri=$NEWRELIC_LOGS_URI \
      --set newrelic.metrics_uri=$NEWRELIC_METRICS_URI \
      --set jfrog.observability.jpd_url=$JPD_URL \
      --set jfrog.observability.username=$JPD_ADMIN_USERNAME \
      --set jfrog.observability.common_jpd=$COMMON_JPD \
      -f log-vendors/NewRelic/helm/artifactory-values.yaml -f helm/artifactory-shared-values.yaml \
      -n $INST_NAMESPACE
   ```

   </details>

#### Artifactory-HA ⎈:

1. Skip this step if you already have Artifactory installed. Else, install Artifactory using the command below

   ```bash
   helm upgrade --install artifactory-ha jfrog/artifactory-ha \
      --set artifactory.masterKey=$MASTER_KEY \
      --set artifactory.joinKey=$JOIN_KEY \
      -n $INST_NAMESPACE
   ```
2. Once Artifactory installation was completed successfully, create a secret for JFrog's admin token - [Access Token](https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory) using any of the following methods

   ```bash
   kubectl create secret generic jfrog-admin-token --from-file=token=<path_to_token_file>
   ```

   OR

   ```bash
   kubectl create secret generic jfrog-admin-token --from-literal=token=<JFROG_ADMIN_TOKEN>
   ``` 
3. Set environment variables for your integration:

   <details><summary>Set environment variables for the Splunk integration</summary>

   Download the .env file from [here](log-vendors/Splunk/helm/jfrog_helm.env). Fill in the jfrog_helm.env file with correct values:

   <ul>
      <li><b>SPLUNK_COM_PROTOCOL</b>: HTTP Scheme, http or https</li>
      <li><b>SPLUNK_HEC_HOST</b>: Splunk Instance URL</li>
      <li><b>SPLUNK_HEC_PORT</b>: Splunk HEC configured port</li>
      <li><b>SPLUNK_HEC_TOKEN</b>: Splunk HEC Token for sending logs to Splunk</li>
      <li><b>SPLUNK_METRICS_HEC_TOKEN</b>: Splunk HEC Token for sending metrics to Splunk</li>
      <li><b>SPLUNK_INSECURE_SSL</b>: false for test environments only or if http scheme</li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>
   Apply the .env file that you created in the previous step, using the command below

   ```bash
   source jfrog_helm.env
   ```

   In order to verify that your environment variables are set correctly, run the following commands::

   ```bash
      env_vars=("SPLUNK_COM_PROTOCOL" "SPLUNK_HEC_HOST" "SPLUNK_HEC_PORT" "SPLUNK_HEC_TOKEN" "SPLUNK_METRICS_HEC_TOKEN" "SPLUNK_INSECURE_SSL" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```
   </details>
   <details><summary>Set environment variables for the DataDog integration</summary>

   Download the .env file from [here](log-vendors/DataDog/helm/jfrog_helm.env). Fill in the jfrog_helm.env file with correct values:

   <ul>
      <li><b>JF_PRODUCT_DATA_INTERNAL</b>: Helm based installs will already have this defined based upon the underlying Docker images. Not a required field for k8s installation</li>
      <li><b>DATADOG_API_KEY</b>: API Key from <a href="https://app.datadoghq.com/organization-settings/api-keys">Datadog</a></li>
      <li><b>DATADOG_API_HOST</b>: Your DataDog host based on your <a href="https://docs.datadoghq.com/getting_started/site/#access-the-datadog-site">DataDog Site Parameter from this list</a></li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-Kubernetes installations or installations where the JPD base URL is the same to access both Artifactory and Xray (for example, `https://sample_base_url/artifactory` or `https://sample_base_url/xray`)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>
   Apply the .env file that you created in the previous step, using the command below

   ```bash
   source jfrog_helm.env
   ```

   In order to verify that your environment variables are set correctly, run the following commands:

   ```bash
      env_vars=("DATADOG_API_KEY" "DATADOG_API_HOST" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```
   </details>
   <details><summary>Set environment variables for the New Relic integration</summary>

   Download the .env file from [here](log-vendors/NewRelic/helm/jfrog_helm.env). Fill in the jfrog_helm.env file with correct values:

   <ul>
      <li><b>NEWRELIC_LICENSE_KEY</b>: License Key from <a href="https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher">NewRelic</a></li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
      <li><b>NEWRELIC_LOGS_URI</b>: This New Relic logs endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://log-api.newrelic.com/log/v1 if isn't set</li>
      <li><b>NEWRELIC_METRICS_URI</b>: This New Relic metrics endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://metric-api.newrelic.com/metric/v1 if isn't set</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>
   Apply the .env file that you created in the previous step, using the command below

   ```bash
   source jfrog_helm.env
   ```

   In order to verify that your environment variables are set correctly, run the following commands:

   ```bash
      env_vars=("NEWRELIC_LICENSE_KEY" "NEWRELIC_LOGS_URI" "NEWRELIC_METRICS_URI" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```
   </details>
4. Apply the .env files and then run the helm command below

   ```bash
   source jfrog_helm.env
   ```
5. Postgres password is required to upgrade Artifactory. Run the following command to get the current password

   ```bash
   POSTGRES_PASSWORD=$(kubectl get secret artifactory-ha-postgresql -n $INST_NAMESPACE -o jsonpath="{.data.postgresql-password}" | base64 --decode)
   ```
6. Upgrade Artifactory HA installation using the command below:

   <details><summary>Upgrade Artifactory HA with Splunk integration</summary>

   ```bash
   helm upgrade --install artifactory-ha  jfrog/artifactory-ha \
       --set artifactory.joinKey=$JOIN_KEY \
       --set postgresql.postgresqlPassword=$POSTGRES_PASSWORD \
       --set splunk.host=$SPLUNK_HEC_HOST \
       --set splunk.port=$SPLUNK_HEC_PORT \
       --set splunk.logs_token=$SPLUNK_HEC_TOKEN \
       --set splunk.metrics_token=$SPLUNK_METRICS_HEC_TOKEN \
       --set splunk.com_protocol=$SPLUNK_COM_PROTOCOL \
       --set splunk.insecure_ssl=$SPLUNK_INSECURE_SSL \
       --set jfrog.observability.jpd_url=$JPD_URL \
       --set jfrog.observability.username=$JPD_ADMIN_USERNAME \
       --set jfrog.observability.common_jpd=$COMMON_JPD \
       -f log-vendors/Splunk/helm/artifactory-values.yaml -f helm/artifactory-shared-values.yaml \
       -n $INST_NAMESPACE
   ```

   </details>
   <details><summary>Upgrade Artifactory HA with DataDog integration</summary>

   ```bash
   helm upgrade --install artifactory-ha  jfrog/artifactory-ha \
      --set artifactory.joinKey=$JOIN_KEY \
      --set postgresql.postgresqlPassword=$POSTGRES_PASSWORD \
      --set datadog.api_key=$DATADOG_API_KEY \
      --set datadog.api_host=$DATADOG_API_HOST \
      --set jfrog.observability.jpd_url=$JPD_URL \
      --set jfrog.observability.username=$JPD_ADMIN_USERNAME \
      --set jfrog.observability.common_jpd=$COMMON_JPD \
      -f log-vendors/DataDog/helm/artifactory-values.yaml -f helm/artifactory-shared-values.yaml \
      -n $INST_NAMESPACE
   ```

   </details>
   <details><summary>Upgrade Artifactory HA with New Relic integration</summary>

   ```bash
   helm upgrade --install artifactory-ha  jfrog/artifactory-ha \
      --set artifactory.joinKey=$JOIN_KEY \
      --set postgresql.postgresqlPassword=$POSTGRES_PASSWORD \
      --set jfrog.observability.jpd_url=$JPD_URL \
      --set jfrog.observability.username=$JPD_ADMIN_USERNAME \
      --set jfrog.observability.common_jpd=$COMMON_JPD \
      --set newrelic.license_key=$NEWRELIC_LICENSE_KEY \
      --set newrelic.logs_uri=$NEWRELIC_LOGS_URI \
      --set newrelic.metrics_uri=$NEWRELIC_METRICS_URI \
      -f log-vendors/NewRelic/helm/artifactory-values.yaml -f helm/artifactory-shared-values.yaml \
      -n $INST_NAMESPACE
   ```
   </details>

#### Xray ⎈:

1. Create a secret for JFrog's admin token - [Access Token](https://jfrog.com/help/r/how-to-generate-an-access-token-video/artifactory-creating-access-tokens-in-artifactory) using any of the following methods if it doesn't exist

   ```bash
   kubectl create secret generic jfrog-admin-token --from-file=token=<path_to_token_file>
   ```

   OR

   ```bash
   kubectl create secret generic jfrog-admin-token --from-literal=token=<JFROG_ADMIN_TOKEN>
   ```
2. For Xray installation, download the .env file  as instructed below and fill in the jfrog_helm.env file with correct values
   <details><summary>Set environment variables for the Splunk integration</summary>

   Download the .env file from [here](log-vendors/Splunk/helm/jfrog_helm.env). Fill in the jfrog_helm.env file with correct values:

   <ul>
      <li><b>SPLUNK_COM_PROTOCOL</b>: HTTP Scheme, http or https</li>
      <li><b>SPLUNK_HEC_HOST</b>: Splunk Instance URL</li>
      <li><b>SPLUNK_HEC_PORT</b>: Splunk HEC configured port</li>
      <li><b>SPLUNK_HEC_TOKEN</b>: Splunk HEC Token for sending logs to Splunk</li>
      <li><b>SPLUNK_METRICS_HEC_TOKEN</b>: Splunk HEC Token for sending metrics to Splunk</li>
      <li><b>SPLUNK_INSECURE_SSL</b>: false for test environments only or if http scheme</li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>
   Apply the .env file that you created in the previous step, using the command below

   ```bash
   source jfrog_helm.env
   ```

   In order to verify that your environment variables are set correctly, run the following commands::

   ```bash
      env_vars=("SPLUNK_COM_PROTOCOL" "SPLUNK_HEC_HOST" "SPLUNK_HEC_PORT" "SPLUNK_HEC_TOKEN" "SPLUNK_METRICS_HEC_TOKEN" "SPLUNK_INSECURE_SSL" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```
   </details>
   <details><summary>Set environment variables for the DataDog integration</summary>

   Download the .env file from [here](log-vendors/DataDog/helm/jfrog_helm.env). Fill in the jfrog_helm.env file with correct values:

   <ul>
      <li><b>JF_PRODUCT_DATA_INTERNAL</b>: Helm based installs will already have this defined based upon the underlying Docker images. Not a required field for k8s installation</li>
      <li><b>DATADOG_API_KEY</b>: API Key from <a href="https://app.datadoghq.com/organization-settings/api-keys">Datadog</a></li>
      <li><b>DATADOG_API_HOST</b>: Your DataDog host based on your <a href="https://docs.datadoghq.com/getting_started/site/#access-the-datadog-site">DataDog Site Parameter from this list</a></li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-Kubernetes installations or installations where the JPD base URL is the same to access both Artifactory and Xray (for example, `https://sample_base_url/artifactory` or `https://sample_base_url/xray`)</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>
   Apply the .env file that you created in the previous step, using the command below

   ```bash
   source jfrog_helm.env
   ```

   In order to verify that your environment variables are set correctly, run the following commands:

   ```bash
      env_vars=("DATADOG_API_KEY" "DATADOG_API_HOST" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```
   </details>
   <details><summary>Set environment variables for the New Relic integration</summary>

   Download the .env file from [here](log-vendors/NewRelic/helm/jfrog_helm.env). Fill in the jfrog_helm.env file with correct values:

   <ul>
      <li><b>NEWRELIC_LICENSE_KEY</b>: License Key from <a href="https://one.newrelic.com/launcher/api-keys-ui.api-keys-launcher">NewRelic</a></li>
      <li><b>JPD_URL</b>: Artifactory JPD URL of the format `http://<ip_address>`</li>
      <li><b>JPD_ADMIN_USERNAME</b>: Artifactory username for authentication</li>
      <li><b>COMMON_JPD</b>: This flag should be set as true only for non-kubernetes installations or installations where JPD base URL is same to access both Artifactory and Xray (ex: https://sample_base_url/artifactory or https://sample_base_url/xray)</li>
      <li><b>NEWRELIC_LOGS_URI</b>: This New Relic logs endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://log-api.newrelic.com/log/v1 if isn't set</li>
      <li><b>NEWRELIC_METRICS_URI</b>: This New Relic metrics endpoint needs to be set if your New Relic instance is in the EU region (or if any other custom configuration is needed). It defaults to https://metric-api.newrelic.com/metric/v1 if isn't set</li>
      <li><b>TARGET_PLATFORM</b>: The target observability platform. Supported platforms: [DATADOG, NEWRELIC, SPLUNK]</li>
   </ul>
   Apply the .env file that you created in the previous step, using the command below

   ```bash
   source jfrog_helm.env
   ```

   In order to verify that your environment variables are set correctly, run the following commands:

   ```bash
      env_vars=("NEWRELIC_LICENSE_KEY" "NEWRELIC_LOGS_URI" "NEWRELIC_METRICS_URI" "JPD_URL" "JPD_ADMIN_USERNAME" "COMMON_JPD" "TARGET_PLATFORM")
      ./test_envs.sh $env_vars
   ```
   </details>
3. Generate a master key for xray

   ```bash
   export XRAY_MASTER_KEY=$(openssl rand -hex 32)
   ```
4. Use the same `joinKey` as you used in Artifactory installation to allow Xray node to successfully connect to Artifactory.

   <details><summary>Install Xray with Splunk integration</summary>

   ```bash
   helm upgrade --install xray jfrog/xray --set xray.jfrogUrl=$JPD_URL \
      --set xray.masterKey=$XRAY_MASTER_KEY \
      --set xray.joinKey=$JOIN_KEY \
      --set splunk.host=$SPLUNK_HEC_HOST \
      --set splunk.port=$SPLUNK_HEC_PORT \
      --set splunk.logs_token=$SPLUNK_HEC_TOKEN \
      --set splunk.metrics_token=$SPLUNK_METRICS_HEC_TOKEN \
      --set splunk.com_protocol=$SPLUNK_COM_PROTOCOL \
      --set splunk.insecure_ssl=$SPLUNK_INSECURE_SSL \
      --set jfrog.observability.jpd_url=$JPD_URL \
      --set jfrog.observability.username=$JPD_ADMIN_USERNAME \
      --set jfrog.observability.common_jpd=$COMMON_JPD \
      -f log-vendors/Splunk/helm/xray-values.yaml -f helm/xray-shared-values.yaml \
      -n $INST_NAMESPACE
   ```

   </details>
   <details><summary>Install Xray with DataDog integration</summary>

   ```bash
   helm upgrade --install xray jfrog/xray --set xray.jfrogUrl=$JPD_URL \
       --set xray.masterKey=$XRAY_MASTER_KEY \
       --set xray.joinKey=$JOIN_KEY \
       --set datadog.api_key=$DATADOG_API_KEY \
       --set datadog.api_host=$DATADOG_API_HOST \
       --set jfrog.observability.jpd_url=$JPD_URL \
       --set jfrog.observability.username=$JPD_ADMIN_USERNAME \
       --set jfrog.observability.common_jpd=$COMMON_JPD \
       -f log-vendors/DataDog/helm/xray-values.yaml -f helm/xray-shared-values.yaml \
       -n $INST_NAMESPACE
   ```

   </details>
   <details><summary>Install Xray with New Relic integration</summary>

   ```bash
   helm upgrade --install xray jfrog/xray --set xray.jfrogUrl=http://my-artifactory-nginx-url \
      --set xray.masterKey=$XRAY_MASTER_KEY \
      --set xray.joinKey=$JOIN_KEY \
      --set datadog.api_key=$DATADOG_API_KEY \
      --set datadog.api_host=$DATADOG_API_HOST \
      --set jfrog.observability.jpd_url=$JPD_URL \
      --set jfrog.observability.username=$JPD_ADMIN_USERNAME \
      --set jfrog.observability.common_jpd=$COMMON_JPD \
      -f log-vendors/NewRelic/helm/xray-values.yaml -f helm/xray-shared-values.yaml \
      -n $INST_NAMESPACE
   ```

   </details>

## Dashboards

### Integrations Dashboards

Dashboards are unique to your observability provider. For more information regarding integration specific dashboards please visit:

* [**Splunk Dashboards**](log-vendors/Splunk#dashboards)
* [**DataDog Dashboards**](log-vendors/DataDog/#dashboards)
* [**New Relic Dashboards**](log-vendors/NewRelic/#dashboards)

## References

* [Fluentd](https://www.fluentd.org) - Fluentd Logging Aggregator/Agent
* [JFrog SIEM plugin](https://github.com/jfrog/fluent-plugin-jfrog-siem) - Fleuntd input plugin to source JFrog Xray Violations
