#!/bin/bash

## Util functions
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

# Modify conf file
modify_conf_file() {
  now_date=$(date +"%m_%d_%Y_%H_%M_%S")
  backup_postfix="_la_backup_$now_date"
  # backup modifying file first
  file_path=$1
  file_path_backup="${file_path}${backup_postfix}"
  conf_content=$2
  sudo cp "${file_path}" "${file_path_backup}"
  echo "Modifying ${file_path}..."
  echo "$conf_content" | sudo tee -a "$file_path"
  echo "File ${file_path} modified and the original content backed up to ${file_path_backup}"
}

update_permissions() {
  group=$1
  default_path=$2
  echo ----------------------------------------
  update_perm=$(question "Would you like to update the $group log permissions? [y/n]: ")
  if [ "$update_perm" == true ]; then
    {
      read -p "Please provide $group path [default: ${default_path}]:" product_path
      if [ -z "$product_path" ]; then
        product_path=$default_path
      fi
      sudo usermod -a -G "$group" td-agent
      echo Updating ${product_path}/log ...
      sudo sh -c 'chmod 0770 '"$product_path"'/log'
      sudo sh -c 'chmod 0640 '"$product_path"'/log/*.log'
    } || {
      echo Error. The permissions update for "$group" wasn\'t successful.
    }
  fi
}

download_install_td_4() {
  script_url=$1
  # check url
  curl -L -f "$script_url" || error_script=true
  if [ $error_script == true ]; then
    echo "ERROR: Error while downloading ${script_url}. Fluentd was NOT installed. Exiting..."
    exit 1
  fi
  # install td-agent script
  curl -L -f "$script_url" | sh
}

## Fluentd Install Script
help_link=https://github.com/jfrog/log-analytics
echo ==================================================================
echo *EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*
echo ==================================================================
echo 'The script performs the following tasks:'
echo '- Downloads the github repo and all dependencies [optional].'
echo '- Checks if the Fluentd requirements are met and updates the OS if needed [optional].'
echo '- Installs/Updates Fluentd as a service depending on Linux distro (Centos and Amazon is supported, more to come).'
echo '- Updates the log files/folders permissions [optional].'
echo '- Installs Fluentd plugins (Splunk, Datadog, Elastic, Prometheus) [optional].'
echo '- Starts and enables the Fluentd service [optional].'
echo '- Provides additional info related to the installed plugins.'
echo More information: $help_link
echo ==================================================================
echo *EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*
echo ==================================================================

# const
supported_distros=("centos" "amazon")

# Check distro
detected_distro=$(cat /etc/*-release | tr [:upper:] [:lower:] | grep -Poi '(centos|ubuntu|red hat|amazon|debian)' | uniq)
supported_distros=("centos" "amazon")
is_supported_distro=false
for supported_distro in "${supported_distros[@]}"; do
  if [[ $detected_distro == $supported_distro ]]; then
    is_supported_distro=true
    break
  fi
done

if [ "$is_supported_distro" == false ]; then
  echo "Linux distro '${detected_distro}' is not supported. Fluentd was NOT installed. Exiting..."
  exit 0
fi

# Experimental warning
experiments_warning=$(question "The installer is still in the EXPERIMENTAL phase (might be unstable). Would you like to continue? [y/n]: ")
if [ "$experiments_warning" == false ]; then
  echo Have a nice day! Good Bye!
  exit 0
fi

# Clone github repository?
clone_repo=$(question "Would you like to clone JFrog log analytics GitHub repository (optional and not required)? [y/n]: ")
if [ "$clone_repo" == true ]; then
  {
    repo_url="https://github.com/jfrog/log-analytics.git"
    echo Cloning repository ${repo_url}
    git clone $repo_url --recursive
    echo Cloning dependencies...
    cd log-analytics
    git submodule foreach git checkout master
    git submodule foreach git pull origin master
  } || {
    echo ERROR: Error while cloning the repository. Fluentd was NOT installed. Exiting...
    exit 1
  }
fi

# Check the Fluentd requirements (file descriptors, etc)
ulimit_output=$(ulimit -n)
if [ $ulimit_output -lt 65536 ]; then
  # Update the file descriptors limit per process and 'high load environments' if needed
  echo ----------------------------------------
  update_limit=$(question "Fluentd requires higher limit of the file descriptors per process and the network kernel parameters adjustment (more info: https://docs.fluentd.org/installation/before-install). Would you like to update the mentioned configuration (sudo rights required)? [y/n]: ")
  if [ $update_limit == true ]; then
    limit_conf_file_path=/etc/security/limits.conf
    limit_config="
# Added by JFrog log-analytics install script
root soft nofile 65536
root hard nofile 65536
* soft nofile 65536
* hard nofile 65536"
    modify_conf_file $limit_conf_file_path "$limit_config"
    nkp_path_file=/etc/sysctl.conf
    nkp_config="
# Added by JFrog log-analytics install script
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240 65535"
    modify_conf_file $nkp_path_file "$nkp_config"
  fi
fi

# We support two ways of installing td-agent4 and user/zip.
echo -----------------------------------------------------
install_as_service=$(question "Would you like to install Fluentd as service?
Yes - Fluentd will be installed as service (sudo rights required).
No  - Fluentd will be installed in a folder specified in the next step (read/write permissions required).
[y/n]: ")

if [ "$install_as_service" == true ]; then
  # Fetches and installs td-agent4 (for now only Centos and Amazon distros supported)
  if [ "$detected_distro" == "centos" ]; then
    error_message="ERROR: td-agent 4 installation failed. Fluentd was NOT installed. Exiting..."
    echo "Centos detected. Installing td-agent 4..."
    {
      download_install_td_4 "https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh"
    } || {
      echo "$error_message"
      exit 1
    }
    update_log_permissions=true
  elif [ "$detected_distro" == "amazon" ]; then
    echo "Amazon Linux detected. Installing td-agent 4..."
    {
      download_install_td_4 "https://toolbelt.treasuredata.com/sh/install-amazon2-td-agent4.sh"
    } || {
      echo "$error_message"
      exit 1
    }
    update_log_permissions=true
  else
    echo "Unsupported (${detected_distro}) Linux distro."
    update_log_permissions=false
  fi
  if [ "$update_log_permissions" == true ]; then
    # Update the log permissions/users artifactory
    update_permissions "artifactory" "/var/opt/jfrog/artifactory"
    # Update the log permissions/users xray
    update_permissions "xray" "/var/opt/jfrog/xray"
  fi
else
  fluentd_file_name="fluentd-1.11.0-linux-x86_64.tar.gz"
  zip_install_default_path="/var/opt/jfrog/artifactory"
  read -p "Please provide a path where Fluentd will be installed, eg. artifactory path, xray, etc. [artifactory default: $zip_install_default_path]: " user_install_path
  # check if the path is empty, if empty then use zip_install_default_path
  if [ -z "$user_install_path" ]; then
    user_install_path=$zip_install_default_path
  fi
  # create folder if not present
  echo Create $user_install_path
  mkdir -p "$user_install_path"
  # check if user has write permissions in the specified path
  if ! [ -w "$user_install_path" ]; then
    echo "ERROR: Write permission denied in ${user_install_path}. Please make sure that you have read/write permissions in ${user_install_path}. Fluentd was NOT installed. Exiting..."
    exit 0
  fi
  # cd to the specified folder
  cd "$user_install_path"
  # download and extract
  wget https://github.com/jfrog/log-analytics/raw/master/fluentd-installer/${fluentd_file_name}
  tar -xvf $fluentd_file_name
  # clean up
  rm $fluentd_file_name
  # This folder/file name extraction is far from perfect, fix it!
  user_install_fluentd_path="$user_install_path/${fluentd_file_name%.*.*}"
fi

# Install additional plugins (splunk, datadog, elastic)
config_link=$help_link
install_plugins=$(question "Would you like to install additional Fluentd plugins: e.g. Splunk, Datadog, Elastic, etc? [y/n]: ")
# check if gem/td-agent-gem is installed
if [ -x "$(command -v td-agent-gem)" ]; then
  gem_command="sudo td-agent-gem"
elif [ -x "$(command -v ${user_install_fluentd_path}/lib/ruby/bin/gem -v)" ]; then
  gem_command="${user_install_fluentd_path}/lib/ruby/bin/gem"
else
  echo "WARNING: Ruby 'gem' or 'td-agent-gem' is required and was not found, please make sure that at least one of the mentioned frameworks is installed. Fluentd plugin installation aborted."
  install_plugins=false
fi
if [ "$install_plugins" == true ]; then
  while true; do
    read -p "What plugin would you like to install [Splunk, Datadog, Prometheus or Elastic]: " plugin_name
    plugin_name=${plugin_name,,}
    case $plugin_name in
    [splunk]*)
      echo Installing fluent-plugin-splunk-enterprise...
      $gem_command install fluent-plugin-splunk-enterprise
      help_link=https://github.com/jfrog/log-analytics-splunk
      break
      ;;
    [datadog]*)
      echo Installing fluent-plugin-datadog...
      $gem_command install fluent-plugin-datadog
      help_link=https://github.com/jfrog/log-analytics-datadog
      break
      ;;
    [elastic]*)
      echo Installing fluent-plugin-elasticsearch...
      $gem_command install fluent-plugin-elasticsearch
      help_link=https://github.com/jfrog/log-analytics-elastic
      break
      ;;
    [prometheus]*)
      echo Installing fluent-plugin-prometheus...
      $gem_command install fluent-plugin-prometheus
      help_link=https://github.com/jfrog/log-analytics-prometheus
      break
      ;;
    *) echo "Please answer Splunk, Datadog or Elastic." ;;
    esac
  done
fi

# Start/enable/status td-agent service
if [ "$install_as_service" == true ]; then
  # enable and start fluentd service, this part is only available if Fluentd was installed as service in the previous steps
  start_enable_serviceservice=$(question "Would you like to start and enable Fluentd service (td-agent4)? [y/n]: ")
  fluentd_service_name="td-agent"
  if [ "$start_enable_serviceservice" == true ]; then
    echo ----------------------------------------
    echo Starting and enabling td-agent service...
    if [[ $(systemctl) =~ -\.mount ]]; then
      sudo systemctl enable ${fluentd_service_name}.service
      sudo systemctl start ${fluentd_service_name}.service
      sudo systemctl status ${fluentd_service_name}.service
    else
      sudo chkconfig ${fluentd_service_name} on
      sudo /etc/init.d/${fluentd_service_name} start
      sudo /etc/init.d/${fluentd_service_name} status
    fi
  fi
else
  start_enable_tar_install=$(question "Would you like to start and enable Fluentd as service (systemctl required)? [y/n]: ")
  if ! [[ $(systemctl) =~ -\.mount ]]; then
    echo "WARNING: The 'systemctl' command not found, the files needed to start Fluentd as service won't be created."
  elif [ "$start_enable_tar_install" == true ]; then
    echo ----------------------------------------
    echo Creating files needed for the Fluentd service...
    mkdir -p "$HOME"/.config/systemd/user/
    fluentd_service_name=jfrogfluentd
    user_install_fluentd_service_conf_file="$HOME"/.config/systemd/user/${fluentd_service_name}.service
    touch "$user_install_fluentd_service_conf_file"
    echo "# Added by JFrog log-analytics install script
[Unit]
Description=JFrog_Fluentd

[Service]
ExecStart=${user_install_fluentd_path}/fluentd ${user_install_fluentd_path}/test.conf
Restart=always

[Install]
WantedBy=graphical.target" >"$user_install_fluentd_service_conf_file"
    echo Starting and enabling td-agent service...
    systemctl --user enable "${user_install_fluentd_service_conf_file}"
    systemctl --user start ${fluentd_service_name}
  fi
fi

if [[ -z $(ps aux | grep fluentd | grep -v "grep") ]]; then
  fluentd_service_msg="WARNING: Service ${fluentd_service_name} not found. Fluentd is not available as service."
else
  if [ "$install_as_service" == true ]; then
    fluentd_conf_file_msg="Fluentd td-agent conf file: /etc/td-agent/td-agent.conf"
  else
    fluentd_conf_file_msg="To change loaded Fluentd configuration please update: ${fluentd_conf_file} ${user_install_fluentd_service_conf_file}"
  fi
  fluentd_service_msg="Service ${fluentd_service_name} was successfully started! ${fluentd_conf_file_msg}"
fi

# Fin!
# TODO Better error handling needed so we're 100% sure that it's actually successful.
echo ===============================================================
echo Fluentd was successfully installed!
echo "${fluentd_service_msg}"
echo The Fluentd configuration might require addition steps, more info: $config_link
echo ===============================================================
