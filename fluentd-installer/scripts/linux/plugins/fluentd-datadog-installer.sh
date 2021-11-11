#!/bin/bash

temp_folder='/tmp'

# load common functions
source ./utils/common.sh # TODO Update the path (git raw)

init() {
  ## Datadog - Fluentd Install Script
  help_link=https://github.com/jfrog/log-analytics-datadog
  echo
  echo ============================================================================================
  echo 'Installing and configuring Datadog plugin for fluentd.The installation script performs the following tasks:'
  echo '- Configure Datadog for JFrog artifactory, xray, etc'
  echo
  echo "More information: $help_link"
  echo ============================================================================================
  echo
}

jfrog_env_variables() {
  # default product path
  jf_default_path_value=$1
  jf_product_data_default_name=$2
  fluentd_as_service=$3
  group=$4
  echo
  read -p "Please provide path for $jf_product_data_default_name. (default: $jf_default_path_value): " user_product_path
  # check if the path is empty, if empty then use default
  if [ -z "$user_product_path"]; then
    echo "Using the default value $jf_default_path_value"
    user_product_path=$jf_default_path_value
  fi
  if [ ! -d "$user_product_path" ]; then
    echo "Incorrect product path $user_product_path"
    echo "Please try again."
    jfrog_env_variables $jf_default_path_value $jf_product_data_default_name $fluentd_as_service
  fi
  # update the product path if needed (remove / if needed)
  if [ "${user_product_path: -1}" == "/" ]; then
    user_product_path=${user_product_path::-1}
  fi
  jf_product_var_path_string="JF_PRODUCT_DATA_INTERNAL=$user_product_path"
  echo "Setting the product path for JF_PRODUCT_DATA_INTERNAL=$user_product_path"
  if [ $fluentd_as_service = true ]; then # fluentd as service
    # update the service with the envs
    env_conf_file='/usr/lib/systemd/system/td-agent.service'
    jf_product_path_string="Environment=$jf_product_var_path_string"
    if grep -q "$jf_product_path_string" $env_conf_file; then
      echo "File $env_conf_file already contains the variables: $jf_product_var_path_string."
    else
      sudo sed -i "/^\[Service\]/a $jf_product_path_string" $env_conf_file
    fi
    update_permissions $user_product_path "td-agent" true
  else
    # update the user profile with the envs (fluentd as user install)
    env_conf_file="$HOME/.bashrc"
    jf_product_path_string="export $jf_product_var_path_string"
    if grep -q "'$jf_product_path_string'" $env_conf_file; then
      echo "File $env_conf_file already contains the variables: $jf_product_var_path_string."
    else
      echo "$jf_product_path_string # Added by the Jfrog Datadog install script" >> $env_conf_file
    fi
    update_permissions $user_product_path $USER true
  fi
  echo "Variable: $jf_product_path_string added to $env_conf_file"
  echo
}

download_configuration_file() {
  fluentd_conf_name=$1
  fluentd_conf_path="$temp_folder/$fluentd_conf_name"
  wget -O $fluentd_conf_path "https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/$fluentd_conf_name"
}

configure_fluentd() {
  fluentd_as_service=$1
  user_install_fluentd_install_path=$2

  # Downloading the fluentd config for Datadog based on the user input
  config_download_path_base="https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/"
  while true; do
    read -p 'Type of Datadog configuration: [Artifactory, Xray, Missioncontrol, Distribution or Pipelines]: ' product_name
    case $product_name in
    [artifactory]*)
      jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory' $fluentd_as_service 'artifactory'
      fluentd_conf_name='fluent.conf.rt'
      download_configuration_file $fluentd_conf_name
      break
      ;;
    [xray]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'xray' $fluentd_as_service 'xray'
      fluentd_conf_name='fluent.conf.xray'
      download_configuration_file $fluentd_conf_name
      # required: JPD_URL is the Artifactory JPD URL of the format http://<ip_address> with is used to pull Xray Violations
      configure_fluentd_datadog "Provide JFrog URL (more info: https://www.jfrog.com/confluence/display/JFROG/General+System+Settings): " 'JPD_URL' false $fluentd_as_service
      # required: USER is the Artifactory username for authentication
      configure_fluentd_datadog 'Provide the Artifactory username for authentication (more info: https://www.jfrog.com/confluence/display/JFROG/Users+and+Groups): ' 'USER' false $fluentd_as_service
      # required: JFROG_API_KEY is the Artifactory API Key for authentication
      configure_fluentd_datadog 'Provide the Artifactory API Key for authentication (more info: https://www.jfrog.com/confluence/display/JFROG/User+Profile#UserProfile-APIKey): ' 'JFROG_API_KEY' true $fluentd_as_service
      break
      ;;
    #[nginx]*)
    #  jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory'
    #  fluentd_conf_name='fluent.conf.nginx'
    #  download_configuration_file $fluentd_conf_name
    #  break
    #  ;;
    [missioncontrol]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'mission Control' $fluentd_as_service
      fluentd_conf_name='fluent.conf.missioncontrol'
      download_configuration_file $fluentd_conf_name
      break
      ;;
    [distribution]*)
      jfrog_env_variables '/var/opt/jfrog/distribution/' 'distribution' $fluentd_as_service
      fluentd_conf_name='fluent.conf.distribution'
      download_configuration_file $fluentd_conf_name
      break
      ;;
   [pipelines]*)
     jfrog_env_variables '/opt/jfrog/pipelines/var/' 'pipelines' $fluentd_as_service
      fluentd_conf_name='fluent.conf.pipelines'
      download_configuration_file $fluentd_conf_name
      break
      ;;
    *) echo 'Incorrect value, please try again. ' ;
    esac
  done

  # Update API key datadog
  configure_fluentd_datadog 'Please provide Datadog API KEY (more info: https://docs.datadoghq.com/account_management/api-app-keys): ' 'API_KEY' true $fluentd_as_service

  # copy and save the changes
  # if fluentd is installed as service
  if [ $fluentd_as_service = true ]; then
    fluentd_conf_file_path=/etc/td-agent/td-agent.conf
    backup_timestamp=$(date +%s)
    # if config exists than back-up the old fluentd conf file
    if [ -f "$fluentd_conf_file_path" ]; then
      sudo mv $fluentd_conf_file_path "${fluentd_conf_file_path}_backup_${backup_timestamp}"
    fi
  else # if fluentd is installed as "user installation"
   while true; do
     echo
    read -p "Please provide location where fluentd conf file will be stored (default: $user_install_fluentd_install_path):" fluentd_conf_file_path_base
    # TODO "Trim" the string to make sure that no empty spaces string is passed
    if [ -z "$fluentd_conf_file_path_base" ]; then # empty string use the default value
      fluentd_conf_file_path="$user_install_fluentd_install_path/$fluentd_conf_name"
      break
    elif [ -h "$fluentd_conf_file_path_base" ]; then # user typed the conf path
      fluentd_conf_file_path="$fluentd_conf_file_path_base/$fluentd_conf_name"
      break
    fi
    done
  fi
  # copy the conf file to the td-agent folder/conf
  run_command $fluentd_as_service "cp "$temp_folder/$fluentd_conf_name" $fluentd_conf_file_path"
  echo "Fluentd Datadog conf file was saved in $fluentd_conf_file_path"
  # clean up
  rm -rf $temp_folder/$fluentd_conf_name
}

configure_fluentd_datadog() {
  datadog_conf_question=$1
  datadog_conf_property=$2
  datadog_conf_is_password=$3
  run_as_sudo=$4

  # check if we hide the user input
  echo
  if [ "$datadog_conf_is_password" = true ]; then # hide user input
    echo -n $datadog_conf_question
    read -s datagod_value
  else
    read -p "$datadog_conf_question" datagod_value # don't hide user input
  fi
  # check if the datadog value is empty, if empty then ask again
  if [ -z "$datagod_value" -a "$datagod_value" ]; then
    echo "Incorrect value '$datagod_value', please try again."
    configure_fluentd_datadog "$datadog_conf_question" "$datadog_conf_property" "$ddatadog_conf_is_password" "$run_as_sudo"
  fi
  echo "Updating fluentd conf file - variable $datadog_conf_property"

  # update the config file
  run_command $run_as_sudo "sed -i -e "s,$datadog_conf_property,$datagod_value,g" $fluentd_conf_path"
}

configure_datadog() {
  fluentd_as_service=$1
  user_install_fluentd_file_test_path=$2
  user_install_fluentd_install_path=$3

  #init script
  init

  # init check
  fluentd_check $fluentd_as_service $user_install_fluentd_file_test_path

  # configure fluentd
  configure_fluentd $fluentd_as_service $user_install_fluentd_install_path

  echo
  if [ $fluentd_as_service = true ]; then
    echo "Location of fluentd Datadog conf file $fluentd_conf_file_path"
  else
    echo "To manually start fluentd with the Datadog conf run the following command: $user_install_fluentd_install_path/fluentd $fluentd_conf_file_path"
    print_error "Datadog installation completed. Please make sure fluentd has read/write access to the log folder: '$user_product_path/log'. In some cases it's necessary to reload the environment or logout $USER user before starting fluentd."
  fi
}
