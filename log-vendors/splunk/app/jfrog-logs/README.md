# Splunk Log Analytics Integration
Jfrog Log Analytics for Splunk

## Installation / Configuration

Jfrog unified platform installation of fluentd.

```
Install td-agent on each node
Install td-agent.conf per type on each node
Run the td-agent on each node
```

Splunk setup required:
```
Install the Jfrog Logs App
```
## Getting Started with Splunk searches

Once you have the Jfrog Logs app installed into Splunk and Jfrog Unified platform sending logs over via fluentd you can then search for the log events.

Example search for all log sources:

```
* | spath log_source
```

To view the artifactory-service.log:

```
* | spath log_source | search log_source="jfrog.rt.artifactory.service"
```

### Tools
* [Fluentd](https://www.fluentd.org/) - fluent logging platform

## Contributing
Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags).

## Contact
* Github
