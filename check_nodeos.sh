#!/bin/bash

############################################################################################
#
# This script is activated when keepalived wants to promote a new producer
#
# The plan is to use the producer API to pause/resume progress based on the STATE
#
# There is no provision to restart a downed nodeos process, its assumed this is catered for
#
# Made with <3 by Pete @ Block Matrix
#
# See more EOS nerd shenanigans @ https://github.com/BlockMatrixNetwork
#
############################################################################################

# Change these vars based on your node configuration
NODEOS_HTTP=localhost
NODEOS_PORT=8888
VICTOROPS_WEBHOOK=https://alert.victorops.com/integrations/generic/20131114/alert/d5b810d1-0de0-4b36-aeca-8ac3c1503235/EOS42

# These are sent via keepalived
TYPE=$1
NAME=$2
STATE=$3

# Echo the result of the pause/resume curl and call slack if relevant
# This could be switched out for any service such as Pager Duty, etc
function notify()
{
    MESSAGE=$1
    echo $MESSAGE
      [[ ! -z $VICTOROPS_WEBHOOK ]] && curl -X POST -d '{"entity_id":"keepalived","message_type":"critical","state_message":"$MESSAGE"}' $VICTOROPS_WEBHOOK > /dev/null
}


# Based on the state, perform the relevant action
case $STATE in
    "MASTER") RESULT=$(curl -s "$NODEOS_HTTP:$NODEOS_PORT/v1/producer/resume")
              if [ "$RESULT" == "{\"result\":\"ok\"}" ]
              then
                  notify "$HOSTNAME successfully promoted to the primary producer"
              else
                  notify "$HOSTNAME failed to resume, investigate immediately"
              fi
              exit 0
              ;;
    "BACKUP") RESULT=$(curl -s "$NODEOS_HTTP:$NODEOS_PORT/v1/producer/pause")
              if [ "$RESULT" == "{\"result\":\"ok\"}" ]
              then
                  notify "$HOSTNAME successfully relegated to secondary producer"
              else
                  notify "$HOSTNAME failed to pause, investigate immediately"
              fi
              exit 0
              ;;
esac
