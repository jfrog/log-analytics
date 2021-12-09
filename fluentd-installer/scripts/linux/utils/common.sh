#!/bin/bash

#const colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

# Yes/No Input
question() {
  question_text=$1
  answer=null
  while true; do
    read -p "$question_text" yesno
    case $yesno in
    [Yy]*)
      answer=true
      break
      ;;
    [Nn]*)
      answer=false
      break
      ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
  echo $answer
}

# Check if fluentd installed
fluentd_check() {
  declare fluentd_as_service=$1
  declare user_install_fluentd_file_test_path=$2
  declare no_service_detected_message="No fluentd detected. Please install fluentd before continue (more info: https://github.com/jfrog/log-analytics)"

  # td-agent check
  if [ $fluentd_as_service == true  ]; then
    TD_AGENT_SERVICE_NAME="td-agent.service"
    td_agent_present=$(systemctl list-units --full -all | grep "$TD_AGENT_SERVICE_NAME")
    if [ -z "$td_agent_present" -a "$td_agent_present" != " " ]; then
      terminate "$no_service_detected_message"
    fi
  # user installed fluentd check - check if fluentd file is in the bin folder
  elif [ ! -f "$user_install_fluentd_file_test_path/fluentd" ]; then
    echo $user_install_fluentd_file_test_path
    terminate "$no_service_detected_message"
  fi
}

run_command() {
  declare run_as_sudo=$1
  declare command_string=$2

  # check if run the command as sudo
  if [ $run_as_sudo == true ]; then
    echo "Run '$command_string' as SUDO..."
    declare sudo_cmd="sudo"
  else
    echo "Run '$command_string' as user (non SUDO)..."
    declare sudo_cmd=""
  fi
  # run the command
  echo "Run command: '${sudo_cmd} ${command_string}'"
  {
    ${sudo_cmd} ${command_string}
  } || {
    print_error "Error, command:'$command_string'. Please check the logs for more information. "
  }
}

update_permissions() {
  declare product_path=$1
  declare user_name=$2
  declare run_as_sudo=$3

  echo
  declare update_perm=$(question "Would you like to add user '$user_name' to the product group and update the log folder permissions? (sudo required)? [y/n]: ")
  if [ "$update_perm" == true ]; then
    {
      echo
      read -p "Please provide the product group name (e.g artifactory, xray, etc): " group
      run_command $run_as_sudo "usermod -a -G $group $user_name"
      echo "User $user_name added to $group."
      run_command $run_as_sudo "chmod 0770 $product_path/log -R"
      sudo find $product_path/log/ -name "*.log" -exec chmod 0640 {} \; # TODO this should be rewritten so can be executed with "run_command",
    } || {
      print_error "The permissions update for $group was unsuccessful. Please try to update the log folder permissions manually. The log folder path: $product_path/log."
    }
  else
    print_error "ALERT! You chose not to update the logs folder permissions. Please make sure fluentd has read/write permissions to $product_path folder before continue."
  fi
}

print_error() {
  declare error_message=$1
  echo "$RED$error_message$RESET"
}

print_green() {
  declare message=$1
  echo "$GREEN$message$RESET"
}

# setup the fluentd environment
jfrog_env_variables() {
  declare jf_default_path_value=$1
  declare jf_product_data_default_name=$2
  declare fluentd_as_service=$3
  declare group=$4
  declare install_as_docker=$5
  echo
  read -p "Please provide $jf_product_data_default_name location (path where the log folder is located). (default: $jf_default_path_value): " user_product_path
  # check if the path is empty, if empty then use default
  echo "Provided location: $user_product_path"
  if [ -z "$user_product_path" ]; then
    echo "Using the default value $jf_default_path_value"
    user_product_path=$jf_default_path_value
  fi
  if [ ! -d "$user_product_path" ] && [ "$install_as_docker" == false ]; then
    echo "Incorrect product path $user_product_path"
    echo "Please try again."
    jfrog_env_variables $jf_default_path_value $jf_product_data_default_name $fluentd_as_service $group $install_as_docker
  fi
  # update the product path if needed (remove / if needed)
  if [ "${user_product_path: -1}" == "/" ]; then
    user_product_path=${user_product_path::-1}
  fi

  if [ "$install_as_docker" == false ]; then
    declare jf_product_var_path_string="JF_PRODUCT_DATA_INTERNAL=$user_product_path"
    echo "Setting the product path for JF_PRODUCT_DATA_INTERNAL=$user_product_path"
    if [ $fluentd_as_service == true ]; then # fluentd as service
      # update the service with the envs
      declare env_conf_file='/usr/lib/systemd/system/td-agent.service'
      jf_product_path_string="Environment=$jf_product_var_path_string"
      if grep -q "$jf_product_path_string" $env_conf_file; then
        echo "File $env_conf_file already contains the variables: $jf_product_var_path_string."
      else
        sudo sed -i "/^\[Service\]/a $jf_product_path_string" $env_conf_file
      fi
      update_permissions $user_product_path "td-agent" true
    else
      # update the user profile with the envs (fluentd as user install)
      declare env_conf_file="$HOME/.bashrc"
      jf_product_path_string="export $jf_product_var_path_string"
      if grep -q "'$jf_product_path_string'" $env_conf_file; then
        echo "File $env_conf_file already contains the variables: $jf_product_var_path_string."
      else
        echo "$jf_product_path_string # Added by the fluentd JFrog install script" >> $env_conf_file
      fi
      update_permissions $user_product_path $USER true
    fi
  else
    # update dockerfile
    run_command false "sed -i -e "s,JF_PRODUCT_DATA_INTERNAL_VALUE,$user_product_path,g" $DOCKERFILE_PATH"
  fi
  echo
}

download_fluentd_conf_file() {
  declare fluentd_conf_base_url=$1
  declare fluentd_conf_name=$2
  declare temp_folder=$3
  declare fluentd_conf_file_path="$temp_folder/$fluentd_conf_name"

  wget -O $fluentd_conf_file_path "$fluentd_conf_base_url/$fluentd_conf_name"
}

update_fluentd_config_file() {
  declare fluentd_conf_file_path=$1
  declare conf_question=$2
  declare conf_property=$3
  declare value_is_secret=$4
  declare run_as_sudo=$5

  # check if we hide the user input
  echo
  if [ "$value_is_secret" == true ]; then # hide user input
    echo -n $conf_question
    read -s fluentd_conf_value
  else
    read -p "$conf_question" fluentd_conf_value # don't hide user input
  fi
  # check if the value is empty, if empty then ask again
  if [ -z "$fluentd_conf_value" -a "$fluentd_conf_value" ]; then
    echo "Incorrect value '$fluentd_conf_value', please try again."
    update_fluentd_config_file "$conf_question" "$conf_property" "$value_is_secret" "$run_as_sudo"
  fi

  # update the config file
  {
    run_command $run_as_sudo "sed -i -e "s,$conf_property,$fluentd_conf_value,g" $fluentd_conf_file_path"
    echo "The value was added to fluentd conf file $fluentd_conf_file_path"
  } || {
    print_error "The value was not added to fluentd conf file $fluentd_conf_file_path. Please check the logs for more info."
  }
}

copy_fluentd_conf() {
  declare fluentd_conf_path_base=$1
  declare fluentd_conf_file_name=$2
  declare fluentd_as_service=$3
  declare install_as_docker=$4
  declare temp_folder=$5

  # copy and save the changes
  # if fluentd is installed as service
  if [ "$install_as_docker" == false ]; then
    if [ $fluentd_as_service == true ]; then
      fluentd_conf_file_path="$fluentd_conf_path_base/td-agent.conf"
      declare backup_timestamp=$(date +%s)
      # if config exists than back-up the old fluentd conf file
      if [ -f "$fluentd_conf_file_path" ]; then
        sudo mv $fluentd_conf_file_path "${fluentd_conf_file_path}_backup_${backup_timestamp}"
      fi
    else # if fluentd is installed as "user installation"
     while true; do
      echo
      read -p "Please provide location where fluentd conf file will be stored (default: $fluentd_conf_path_base):" user_fluentd_conf_path
      # TODO "Trim" the string to make sure that no empty spaces string is passed
      if [ -z "$user_fluentd_conf_path" ]; then # empty string use the default value
        fluentd_conf_file_path="$fluentd_conf_path_base/$fluentd_conf_file_name"
        break
      elif [ -h "$user_fluentd_conf_path" ]; then # user typed the conf path
        fluentd_conf_file_path="$user_fluentd_conf_path/$fluentd_conf_file_name"
        break
      fi
      done
    fi
  else
    # in case of docker, copy the fluentd file to the current folder where Dockerfile is
    fluentd_conf_file_path="./"
  fi

  # copy the conf file to the td-agent folder/conf
  {
    run_command $fluentd_as_service "cp $temp_folder/$fluentd_conf_file_name $fluentd_conf_file_path"
    echo "Fluentd conf file was saved in $fluentd_conf_file_path"
    # clean up
    rm -rf $temp_folder/$fluentd_conf_file_name
  } || {
    terminate 'Please review the errors.'
  }
}

install_custom_plugin() {
  declare plugin_name=$1
  declare gem_command=$2
  declare run_as_sudo=$3

  # Install additions plugin (splunk, datadog, elastic)
  echo
  declare user_install_plugin=$(question "Would you like to install $plugin_name plugin [y/n]: ")
  if [ "$user_install_plugin" == true ]; then
    declare lower_case_plugin_name=echo "${plugin_name,,}"
    case  $lower_case_plugin_name in
    [siem]*)
      echo Installing fluent-plugin-jfrog-siem...
      if [ "$install_as_docker" == false ]; then
        run_command $run_as_sudo "$gem_command install fluent-plugin-jfrog-siem" || terminate 'Please review the errors.'
      else
         # add datadog plugin install command to the dockerfile
        echo "RUN fluent-gem install fluent-plugin-jfrog-siem" >> "$DOCKERFILE_PATH"
        echo "RUN fluent-gem install fluent-plugin-record-modifier" >> "$DOCKERFILE_PATH"
      fi
      declare help_link=https://github.com/jfrog/fluent-plugin-jfrog-siem
      ;;
    *) print_error "Plugin $plugin_name not found" ;;
    esac
  fi
}

xray_shared_questions() {
  temp_folder=$1
  fluentd_datadog_conf_name=$2
  gem_command=$3
  fluentd_as_service=$4
  install_as_docker=$5

  # required: JPD_URL is the JPD URL of the format http://<ip_address> with is used to pull Xray Violations
  update_fluentd_config_file "$temp_folder/$fluentd_datadog_conf_name" "Provide JFrog URL (more info: https://www.jfrog.com/confluence/display/JFROG/General+System+Settings): " 'JPD_URL' false $fluentd_as_service
  # required: USER is the JPD username for authentication
  update_fluentd_config_file "$temp_folder/$fluentd_datadog_conf_name" 'Provide the JPD username for authentication (more info: https://www.jfrog.com/confluence/display/JFROG/Users+and+Groups): ' 'USER' false $fluentd_as_service
  # required: JFROG_API_KEY is the JPD API Key for authentication
  update_fluentd_config_file "$temp_folder/$fluentd_datadog_conf_name" 'Provide the JPD API Key for authentication (more info: https://www.jfrog.com/confluence/display/JFROG/User+Profile): ' 'JFROG_API_KEY' true $fluentd_as_service
  # install SIEM plugin
  echo
  install_custom_plugin 'SIEM' "$gem_command" $fluentd_as_service
}

download_dockerfile_template() {
  # downloads Dockerfile template to the current dir
  wget -O "$DOCKERFILE_PATH" https://github.com/jfrog/log-analytics/raw/${GITHUB_BRANCH}/fluentd-installer/scripts/linux/Dockerfile.fluentd
}

finalizing_configuration() {
  declare install_as_docker=$1
  declare fluentd_as_service=$2
  declare fluentd_conf_name=$3
  declare user_install_fluentd_install_path=$4

  if [ "$install_as_docker" == false ]; then
    if [ $fluentd_as_service == true ]; then
      copy_fluentd_conf '/etc/td-agent' "$fluentd_conf_name" $fluentd_as_service $install_as_docker "$TEMP_FOLDER"
    else
      copy_fluentd_conf "$user_install_fluentd_install_path" "$fluentd_conf_name" $fluentd_as_service $install_as_docker "$TEMP_FOLDER"
    fi
  else
    copy_fluentd_conf "$user_install_fluentd_install_path" "$fluentd_conf_name" $fluentd_as_service $install_as_docker "$TEMP_FOLDER"
  fi
}

install_fluentd_plugin() {
  declare fluentd_as_service=$1
  declare install_as_docker=$2
  declare plugin_name=$3
  declare gem_command=$4

  # install slunk fluentd plugin or modify Dockerfile
  if [ "$install_as_docker" == false ]; then
    declare install_plugin_command="$gem_command install $plugin_name"
    # fluentd check
    fluentd_check $fluentd_as_service $user_install_fluentd_install_path
    # install fluentd datadog plugin
    run_command $fluentd_as_service "$install_plugin_command" || terminate "Error while installing $plugin_name plugin."
  else
    # download dockerfile template
    download_dockerfile_template
    # add datadog plugin install command to the dockerfile
    echo "RUN fluent-gem install $plugin_name" >> "$DOCKERFILE_PATH"
  fi
}
