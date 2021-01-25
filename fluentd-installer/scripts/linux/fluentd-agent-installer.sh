#!/bin/sh

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
  update_perm=$(question "Would you like to update the $group log permissions? [y/n]: ");
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

## Fluentd Install Script
help_link=https://github.com/jfrog/log-analytics
echo ==============================================================
echo 'The script performs the following tasks:'
echo  '- Downloads the github repo and all dependencies [optional].'
echo  '- Checks if the Fluentd requirements are met and updates the OS if needed [optional].'
echo  '- Installs/Updates Fluentd as a service depending on Linux distro (Centos and Amazon is supported, more to come).'
echo  '- Updates the log files/folders permissions [optional].'
echo  '- Installs Fluentd plugins (Splunk, Datadog, Elastic)[optional].'
echo  '- Starts and enables the td service [optional].'
echo More information: $help_link
echo ==============================================================

## Clone github repository?
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
    echo Error while cloning the repository.
    exit 0
  }
fi

# Check the Fluentd requirements (file descriptors, etc)
ulimit_output=$(ulimit -n)
if [ $ulimit_output -lt 65536 ]; then
  # Update the file descriptors limit per process and 'high load environments' if needed
  echo ----------------------------------------
  update_limit=$(question "Fluentd requires higher limit of the file descriptors per process and the network kernel parameters adjustment (more info: https://docs.fluentd.org/installation/before-install). Would you like to update the mentioned configuration? [y/n]: ")
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

# Fetch and installing td-agent4 (for now only Centos and Amazon distros)
linux_distro=$(cat /etc/*-release | tr [:upper:] [:lower:] | grep -Poi '(centos|ubuntu|red hat|amazon|debian)' | uniq)
echo ----------------------------------------
if [ "$linux_distro" == "centos" ]; then
  echo "Centos detected. Installing td-agent 4..."
  {
    curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh
  } || {
    echo Error, td agent 4 installation failed
    exit 0
  }
elif [ "$linux_distro" == "amazon" ]; then
  echo "Amazon Linux detected. Installing td-agent 4..."
  {
    curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh
  } || {
    echo Error, td agent 4 installation failed
    exit 0
  }
else
  echo "Unsupported (${linux_distro}) Linux distro."
fi

# Update the log permissions/users artifactory
update_permissions "artifactory" "/var/opt/jfrog/artifactory"

# Update the log permissions/users xray
update_permissions "xray" "/var/opt/jfrog/xray"

# Install additional plugins (splunk, datadog, elastic)
config_link=$help_link
install_plugins=$(question "Would you like to install additional Fluentd plugins like Splunk, Datadog, Elastic, etc? [y/n]: ");
if [ "$install_plugins" == true ]; then
  while true; do
    read -p "What plugin would you like to install [Splunk, Datadog or Elastic]: " plugin_name
    plugin_name=${plugin_name,,}
    case $plugin_name in
    [splunk]*)
      echo Installing fluent-plugin-splunk-enterprise...
      sudo td-agent-gem install fluent-plugin-splunk-enterprise
      help_link=https://github.com/jfrog/log-analytics-splunk
      break
      ;;
    [datadog]*)
      echo Installing fluent-plugin-datadog...
      sudo td-agent-gem install fluent-plugin-datadog
      help_link=https://github.com/jfrog/log-analytics-datadog
      break
      ;;
    [elastic]*)
      echo Installing fluent-plugin-elasticsearch...
      sudo td-agent-gem install fluent-plugin-elasticsearch
      help_link=https://github.com/jfrog/log-analytics-elastic
      break
      ;;
    *) echo "Please answer Splunk, Datadog or Elastic." ;;
    esac
  done
fi

# Start/enable/status td service
start_service=$(question "Would you like to start and enable td-agent service? [y/n]: ");
if [ "$start_service" == true ]; then
  echo ----------------------------------------
  echo Starting and enabling td-agent service...
  if [[ $(systemctl) =~ -\.mount ]]; then
    sudo systemctl enable td-agent.service
    sudo systemctl start td-agent.service
    sudo systemctl status td-agent.service
  else
    sudo chkconfig td-agent on
    sudo /etc/init.d/td-agent start
    sudo /etc/init.d/td-agent status
  fi
fi

# Fin!
# TODO Better error handling needed so we're 100% sure that it's actually successful.
echo ===================================================================================================================
echo Fluentd service was successfully installed!
echo The Fluentd configuration might require addition steps, more info: $config_link
echo ===================================================================================================================
