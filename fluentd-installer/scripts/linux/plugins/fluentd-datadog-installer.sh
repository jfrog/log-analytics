#!/bin/bash

temp_folder='/tmp'

# TODO Proof of concept (datadog/plugin installer) EXPERIMENTAL!
# TODO ONLY fluentd as service installation is supported and ONLY for artifactory (no Xray, etc support)!

# load common functions
source ./utils/common.sh # TODO Update the path (git raw)

init() {
  ## Datadog - Fluentd Install Script
  help_link=https://github.com/jfrog/log-analytics-datadog
  echo
  echo ============================================================================================
  echo 'Installing and configuring Datadog plugin for fluentd...'
  echo
  echo 'The script performs the following tasks:'
  echo '- Configure Datadog for JFrog artifactory'
  echo
  echo "More information: $help_link"
  echo ============================================================================================
  echo
}

jfrog_env_variables() {
  # default product path
  jf_product_data_default_name=$2
  read -p "Please provide path for $jf_product_data_default_name. [default: $1]: " user_product_path
  # check if the path is empty, if empty then use default
  if [ -z "$user_product_path"]; then
    echo Using the default value $1
    user_product_path=$1
  fi
  if [ ! -d "$user_product_path" ]; then
    echo "Incorrect product path $user_product_path"
    echo "Please try again."
    jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory' #TODO make this one interactive
  fi
  # update the product path if needed (remove / if needed)
  if [ "${user_product_path: -1}" == "/" ]; then
    user_product_path=${user_product_path::-1}
  fi
  service_conf_file='/usr/lib/systemd/system/td-agent.service'
  # TODO this step should be optional depending if this is the service or user based install, at this point we do both
  jf_product_string="JF_PRODUCT_DATA_INTERNAL=$user_product_path"
  env_service_jf_product_string="Environment=$jf_product_string"
  echo "Setting the product path to JF_PRODUCT_DATA_INTERNAL=$user_product_path..."
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
  fluentd_conf_path="$temp_folder/$fluentd_conf_name"
  wget -O $fluentd_conf_path "https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/$fluentd_conf_name"
}

configure_fluentd() {
  # Downloading the fluentd config for Datadog based on the user input
  config_download_path_base="https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/"
  while true; do
    read -p 'Type of Datadog configuration: [Artifactory, Xray, Missioncontrol, Distribution or Pipelines]: ' product_name
    case $product_name in
    [artifactory]*)
      jfrog_env_variables '/var/opt/jfrog/artifactory/' 'Artifactory'
      fluentd_conf_name='fluent.conf.rt'
      download_configuration_file $fluentd_conf_name
      break
      ;;
    [xray]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'Xray'
      fluentd_conf_name='fluent.conf.xray'
      download_configuration_file $fluentd_conf_name
      # required: JPD_URL is the Artifactory JPD URL of the format http://<ip_address> with is used to pull Xray Violations
      configure_fluentd_datadog "Provide JFrog URL (more info: https://www.jfrog.com/confluence/display/JFROG/General+System+Settings): " 'JPD_URL' false
      # required: USER is the Artifactory username for authentication
      configure_fluentd_datadog 'Provide the Artifactory username for authentication (more info: https://www.jfrog.com/confluence/display/JFROG/Users+and+Groups): ' 'USER' false
      # required: JFROG_API_KEY is the Artifactory API Key for authentication
      configure_fluentd_datadog 'Provide the Artifactory API Key for authentication (more info: https://www.jfrog.com/confluence/display/JFROG/User+Profile#UserProfile-APIKey): ' 'JFROG_API_KEY' true
      break
      ;;
    #[nginx]*)
    #  jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory'
    #  fluentd_conf_name='fluent.conf.nginx'
    #  download_configuration_file $fluentd_conf_name
    #  break
    #  ;;
    [missioncontrol]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'Mission Control'
      fluentd_conf_name='fluent.conf.missioncontrol'
      download_configuration_file $fluentd_conf_name
      break
      ;;
    [distribution]*)
      jfrog_env_variables '/var/opt/jfrog/distribution/' 'Distribution'
      fluentd_conf_name='fluent.conf.distribution'
      download_configuration_file $fluentd_conf_name
      break
      ;;
   [pipelines]*)
     jfrog_env_variables '/opt/jfrog/pipelines/var/' 'Pipelines'
      fluentd_conf_name='fluent.conf.pipelines'
      download_configuration_file $fluentd_conf_name
      break
      ;;
    *) echo 'Incorrect value, please try again. ' ;
    esac
  done

  # Update API key datadog
  configure_fluentd_datadog 'Please provide Datadog API KEY (more info: https://docs.datadoghq.com/account_management/api-app-keys): ' 'API_KEY' true

  # copy and save the changes
  # TODO it should be interactive in case that the user doesn't use the td-agent service
  fluentd_service_conf_path=/etc/td-agent/td-agent.conf
  backup_timestamp=$(date +%s)
  # if config exists than back-up the old fluentd conf file
  if [ -f "$fluentd_service_conf_path" ]; then
    sudo mv $fluentd_service_conf_path "${fluentd_service_conf_path}_backup_${backup_timestamp}"
  fi
  # copy the conf file to the td-agent folder/conf
  sudo cp "$temp_folder/$fluentd_conf_name" $fluentd_service_conf_path
  echo "Fluentd configuration created for Datadog, product: $product_name."
  echo
  # clean up
  rm -rf $temp_folder/$fluentd_conf_name
}

configure_fluentd_datadog() {
  datadog_conf_question=$1
  datadog_conf_property=$2
  datadog_conf_is_password=$3
  if [ "$datadog_conf_is_password" = true ]; then
    echo -n $datadog_conf_question
    read -s datagod_value
  else
    read -p "$datadog_conf_question" datagod_value
  fi
  # check if the datadog value is empty, if empty then ask again
  if [ -z "$datagod_value" -a "$datagod_value" ]; then
    echo "Incorrect value '$datagod_value', please try again."
    configure_fluentd_datadog "$datadog_conf_question" "$datadog_conf_property"
  fi
  echo "Updating fluentd conf file - variable $datadog_conf_property"
  sudo sed -i -e "s,$datadog_conf_property,$datagod_value,g" $fluentd_conf_path
  #echo "Fluentd conf file updated: ${fluentd_conf_path}"
  #echo "Modifying fluentd service (td-agent)..."
  #fluentd_service_conf_path=/etc/td-agent/td-agent.conf
}

configure_datadog() {
  fluentd_as_service=$1
  user_install_fluentd_file_path=$2

  #init script
  init

  # init check
  fluentd_check $fluentd_as_service $user_install_fluentd_file_path

  # configure fluentd
  configure_fluentd
}
