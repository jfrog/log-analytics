#!/bin/bash

# TODO Proof of concept (datadog/plugin installer) EXPERIMENTAL!
# TODO ONLY fluentd as service installation is supported and ONLY for artifactory (no Xray, etc support)!

init() {
  ## Datadog - Fluentd Install Script
  help_link=https://github.com/jfrog/log-analytics-datadog
  echo ============================================================================================
  echo *EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*
  echo ============================================================================================
  echo
  echo 'Installing Datadog plugin for fluentd...'
  echo
  echo 'The script performs the following tasks:'
  echo '- Configure Datadog for JFrog artifactory (no Xray, etc support).'
  echo
  echo "More information: $help_link"
  echo ============================================================================================
  echo *EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*
  echo ============================================================================================
  echo
}

# Terminate installation
terminate() {
  termination_reason=$1
  echo 'Datadog plugin Installation terminated'
  echo "Reason(s): $termination_reason"
  echo
  echo 'Installation terminated!'
  echo
  exit
}

# Check if fluentd installed
fluentd_agent_check() {
  # td-agent check
  TD_AGENT_SERVICE_NAME="td-agent.service"
  td_agent_present=$(systemctl list-units --full -all | grep "$TD_AGENT_SERVICE_NAME")
  if [ -z "$td_agent_present" -a "$td_agent_present" != " " ]; then
    terminate "No $TD_AGENT_SERVICE_NAME service detected."
  fi
}

jfrog_env_variables() {
  # default product path
  JF_PRODUCT_DATA_INTERNAL=$1
  jf_product_data_default_name=$2
  read -p "Please provide the product path, eg. artifactory path, xray, etc. [default $jf_product_data_default_name: $JF_PRODUCT_DATA_INTERNAL]: " user_product_path
  # check if the path is empty, if empty then use default
  if [ ! -z "$user_product_path" -a "$user_product_path" ]; then
    if [ ! -d "$user_product_path" ]; then
      terminate "Incorrect product path $user_product_path"
    fi
    JF_PRODUCT_DATA_INTERNAL=$user_product_path
  fi
  # update the product path if needed (remove / if needed)
  if [ "${JF_PRODUCT_DATA_INTERNAL: -1}" == "/" ]; then
    JF_PRODUCT_DATA_INTERNAL=${JF_PRODUCT_DATA_INTERNAL::-1}
  fi
  service_conf_file='/usr/lib/systemd/system/td-agent.service'
  # TODO this step should be optional depending if this is the service or user based install, at this point we do both
  jf_product_string="JF_PRODUCT_DATA_INTERNAL=$JF_PRODUCT_DATA_INTERNAL"
  env_service_jf_product_string="Environment=$jf_product_string"
  echo "Setting the product path to JF_PRODUCT_DATA_INTERNAL=$JF_PRODUCT_DATA_INTERNAL..."
  if grep -q $env_service_jf_product_string $service_conf_file; then
    # TODO Replace the existing vars if needed
    sudo echo "File $service_conf_file already contains the variables: $jf_product_string."
  else
    sudo sed -i "/^\[Service\]/a $env_service_jf_product_string" $service_conf_file
    echo "Variable: $env_service_jf_product_string added to $service_conf_file"
  fi
  echo
}

download_configuration_file() {
  fluentd_conf_name=$1
  fluentd_conf_path="$JF_PRODUCT_DATA_INTERNAL$fluentd_conf_name"
  sudo wget -O $fluentd_conf_path wget "https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/$fluentd_conf_name"
}

configure_fluentd() {
  # Downloading the fluentd config for Datadog based on the user input
  config_download_path_base="https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/"
  while true; do
    read -p 'Type name of of the Datadog configuration: [Artifactory, Xray, Missioncontrol, Distribution or Pipelines]: ' product_name
    case $product_name in
    [artifactory]*)
      fluentd_conf_name='fluent.conf.rt'
      download_configuration_file fluentd_conf_name
      break
      ;;
    [xray]*)
      fluentd_conf_name='fluent.conf.xray'
      download_configuration_file $fluentd_conf_name
      # required: JPD_URL is the Artifactory JPD URL of the format http://<ip_address> with is used to pull Xray Violations
      configure_fluentd_datadog 'Provide JFrog URL (JPD_URL): ' 'JPD_URL'
      # required: USER is the Artifactory username for authentication
      configure_fluentd_datadog 'Provide the Artifactory username for authentication (USER): ' 'USER'
      # required: JFROG_API_KEY is the Artifactory API Key for authentication
      configure_fluentd_datadog 'Provide the Artifactory API Key for authentication (JFROG_API_KEY): ' 'JFROG_API_KEY'
      break
      ;;
    [nginx]*)
      fluentd_conf_name='fluent.conf.nginx'
      download_configuration_file $fluentd_conf_name
      break
      ;;
    [missioncontrol]*)
      fluentd_conf_name='fluent.conf.missioncontrol'
      download_configuration_file $fluentd_conf_name
      break
      ;;
    [distribution]*)
      fluentd_conf_name='fluent.conf.distribution'
      download_configuration_file $fluentd_conf_name
      break
      ;;
   [pipelines]*)
      fluentd_conf_name='fluent.conf.pipelines'
      download_configuration_file $fluentd_conf_name
      break
      ;;
    *) echo 'Incorrect value, please try again. ' ;
    esac
  done

  # Update API key datadog
  configure_fluentd_datadog 'Please provide Datadog API KEY (API_KEY). More information (https://docs.datadoghq.com/account_management/api-app-keys): ' 'API_KEY'

  # copy and save the changes
  backup_timestamp=$(date +%s)
  # if config exists than back-up the old fluentd conf file
  if [ -f "$fluentd_service_conf_path" ]; then
    sudo mv $fluentd_service_conf_path "${fluentd_service_conf_path}_backup_${backup_timestamp}"
  fi
  sudo cp $fluentd_conf_path $fluentd_service_conf_path
  echo "Fluentd configuration created for Datadog, product: $product_name."
  echo
}

configure_fluentd_datadog() {
  datadog_conf_question=$1
  datadog_conf_property=$2
  read -p $datadog_conf_question $datagod_value
  # check if the datadog value is empty, if empty then ask again
  if [ -z "$datagod_value" -a "$datagod_value" ]; then
    echo "Incorrect value '$datagod_value', please try again."
    echo
    configure_fluentd_datadog $datadog_conf_question
  fi
  echo "Updating fluentd conf file for Datadog - variable $datadog_conf_property"
  sudo sed -i -e "s/$datadog_conf_property/$datagod_value/g" $fluentd_conf_path
  echo "Fluentd conf file updated: ${fluentd_conf_path}"
  echo "Modifying fluentd service (td-agent)..."
  fluentd_service_conf_path=/etc/td-agent/td-agent.conf
}

#init script
init

# init check
fluentd_agent_check

# select product and set envs
jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory' #TODO make this one interactive

# configure fluentd
configure_fluentd
