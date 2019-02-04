#!/usr/bin/env bash
#
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
#

function real_service() {
  desc=$NAGIOS_SERVICEGROUPNAME
  eval "$1='$desc'"
}

function real_component() {
  arrDesc=(${NAGIOS_SERVICEDESC//::/ })

  compName="${arrDesc[0]}"

  case "$compName" in
    HBASEMASTER)
      realCompName="HBASE_MASTER"
    ;;
    REGIONSERVER)
      realCompName="HBASE_REGIONSERVER"
    ;;
    JOBHISTORY)
      realCompName="MAPREDUCE2"
    ;;
    HIVE-METASTORE)
      realCompName="HIVE_METASTORE"
    ;;
    HIVE-SERVER)
      realCompName="HIVE_SERVER"
    ;;
    FLUME)
      realCompName="FLUME_HANDLER"
    ;;
    HUE)
      realCompName="HUE_SERVER"
    ;;
    HUE_DOCKER)
      realCompName="HUE_SERVER_DOCKER"
    ;;
    WEBHCAT)
      realCompName="WEBHCAT_SERVER"
    ;;
    *)
      realCompName=$compName
    ;;
  esac

  eval "$1='$realCompName'"
}

real_service_var=""
real_service real_service_var

real_comp_var=""
real_component real_comp_var


wrapper_output=`exec "$@"`
wrapper_result=$?

if [ "$wrapper_result" == "0" ]; then
  echo "$wrapper_output"
  exit $wrapper_result
fi

if [ ! -f /var/nagios/ignore.dat ]; then
  echo "$wrapper_output"
  exit $wrapper_result
else
  count=$(grep $NAGIOS_HOSTNAME /var/nagios/ignore.dat | grep $real_service_var | grep $real_comp_var | wc -l)
  if [ "$count" -ne "0" ]; then
    echo "$wrapper_output\nAMBARIPASSIVE=${wrapper_result}" | sed 's/^[ \t]*//g'
    exit 0
  else
    echo "$wrapper_output"
    exit $wrapper_result
  fi
fi

