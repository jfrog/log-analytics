#!/bin/bash

# Common functions

terminate() {
  termination_reason=$1
  echo 'Installation was unsuccessful!'
  echo "Reason(s): $termination_reason"
  echo
  echo 'Installation terminated!'
  echo
  exit 1
}
