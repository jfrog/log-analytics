# Splunk Integration

## Versions Supported

This integration is last tested with Artifactory 7.77.11 and Xray 3.88.12 versions.

## Splunk Setup

### Splunkbase App

Install the `JFrog Log Analytics Platform` app from Splunkbase [here!](https://splunkbase.splunk.com/app/5023/)

````text
1. Download file from Splunkbase
2. Open Splunk web console as administrator
3. From homepage click on settings wheel in top right of Apps section
4. Click on "Install app from file"
5. Select download file from Splunkbase on your computer
6. Click upgrade 
7. Click upload
````

Restart Splunk post installation of App.

````text
1. Open Splunk web console as adminstrator
2. Click on Settings then Server Controls
3. Click on Restart 
````

Login to Splunk after the restart completes.

Confirm the version is the latest version available in Splunkbase.

### Configure Splunk

Our integration uses the [Splunk HEC](https://dev.splunk.com/enterprise/docs/dataapps/httpeventcollector/) to send data to Splunk.

Users will need to configure the HEC to accept data (enabled) and also create a new token. Steps are below.

#### Create index jfrog_splunk

````text
1. Open Splunk web console as administrator
2. Click on "Settings" in dropdown select "Indexes"
3. Click on "New Index"
4. Enter Index name as jfrog_splunk
5. Click "Save"
````

#### Create index jfrog_splunk_metrics

````text
1. Open Splunk web console as administrator
2. Click on "Settings" in dropdown select "Indexes"
3. Click on "New Index"
4. Enter Index name as jfrog_splunk_metrics
5. Select Index Data Type as Metrics
6. Click "Save"
````

#### Configure new HEC token to receive Logs

````text
1. Open Splunk web console as administrator
2. Click on "Settings" in dropdown select "Data inputs"
3. Click on "HTTP Event Collector"
4. Click on "New Token"
5. Enter a "Name" in the textbox
6. (Optional) Enter a "Description" in the textbox
7. Click on the green "Next" button
8. Add "jfrog_splunk" index to store the JFrog platform log data into.
9. Click on the green "Review" button
10. If good, Click on the green "Done" button
11. Save the generated token value
````

#### Configure new HEC token to receive Metrics

````text
1. Open Splunk web console as administrator
2. Click on "Settings" in dropdown select "Data inputs"
3. Click on "HTTP Event Collector"
4. Click on "New Token"
5. Enter a "Name" in the textbox
6. (Optional) Enter a "Description" in the textbox
7. Click on the green "Next" button
8. Add "jfrog_splunk_metrics" index to store the JFrog platform metrics data into.
9. Click on the green "Review" button
10. If good, Click on the green "Done" button
11. Save the generated token value
````
