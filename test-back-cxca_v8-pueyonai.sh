#!/bin/bash

host="hotfix.stage.screening.navify.com"
domain=""
version="/api/v1/"
auth_token_endpoint="/auth/realms/cxca-cockpit/protocol/openid-connect/token"
patient_id="5fecbbde-ea04-423f-8b5f-32cdbd459833"
max_time=150
dns_resolver=""

idp_client_secret='M:vaW-(Eqk(fF3kivgXUryG*$2{C1sa['
#idp_username='devops'
#idp_username='pueyonai'
idp_username='usertest1'
idp_password='DevOps1D!'

show_script_usage() {
	echo "Usage: ./call_patient_relevant_info.sh -e <environment> -t <max_response_time>"
	echo "-e: Environtment values -> hotfix"
	echo "-t: Max Time for response in seconds. 250 by default"
	exit 1
}

get_access_token() {
	local auth_url="https://$host$auth_token_endpoint"
	response=$(curl -s --location "$auth_url" \
	--header "Content-Type: application/x-www-form-urlencoded" \
	--data-urlencode "client_id=cxca" \
	--data-urlencode "grant_type=password" \
	--data-urlencode "client_secret=$idp_client_secret" \
	--data-urlencode "scope=openid" \
	--data-urlencode "username=$idp_username" \
	--data-urlencode "password=$idp_password")

	access_token=$(echo "$response" | grep -o '"access_token": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')
	echo "$access_token"
}

check_response() {

  #echo status_code_response_1="${response}"
	#echo status_code_response_2=${#response}
	status_code=${response:${#response}-3}

	# response without status code
	response=${response:0:${#response}-3}

	if [ -n "$status_code" ]; then
		if [[ $status_code == 499 ]]; then
		  current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
      echo $current_datetime
			echo "HTTP Error 499 raised!"
			return 1
		elif [[ $status_code == 5*  || $status_code == 4* ]]; then
		  current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
      echo $current_datetime
			echo "HTTP Error $status_code"
			echo "Error response: $response"
			return 1
		elif [[ $status_code == 2* ]]; then
		  current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
      echo $current_datetime
			echo "Response received with HTTP $status_code"
			return 0
		else
		  current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
      echo $current_datetime
			echo "No response obtained in $max_time seconds"
			return 1
		fi
	else
	  current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
    echo $current_datetime
	  echo "No response obtained in $max_time seconds"
	  return 1
	fi
}

# No operator present
if [[ ! $@ =~ \-e\ .+ ]]; then
	show_script_usage
fi

while getopts "e:t:" opt; do
  case $opt in
    e)
      if [ "$OPTARG" == "cloudflare" ]; then
				domain="https://$host"
				dns_resolver=""
				json_data='{
          "patientId": "5fecbbde-ea04-423f-8b5f-32cdbd459833",
          "immunosuppressed": {
            "value": "no",
            "detail": "a detailed comment"
          },
          "hpvVaccination": {
            "value": "no",
            "detail": "a detailed comment"
          },
          "contraception": {
            "value": "no",
            "detail": "a detailed comment"
          },
          "smoker": {
            "value": "no",
            "detail": "a detailed comment"
          },
          "others": "a detailed comment"
        }'
			elif [ "$OPTARG" == "loadbalancer" ]; then
				domain="https://$host"
				dns_resolver=" --resolve $host:443:3.73.165.110 " #3.65.242.198
				json_data='{
          "patientId": "5fecbbde-ea04-423f-8b5f-32cdbd459833",
          "immunosuppressed": {
            "value": "yes",
            "detail": "a detailed comment"
          },
          "hpvVaccination": {
            "value": "yes",
            "detail": "a detailed comment"
          },
          "contraception": {
            "value": "yes",
            "detail": "a detailed comment"
          },
          "smoker": {
            "value": "yes",
            "detail": "a detailed comment"
          },
          "others": "a detailed comment"
        }'
			elif [ "$OPTARG" == "nginx" ]; then
				domain="http://$host:9080"
				dns_resolver=" --resolve $host:9080:127.0.0.1 "
			elif [ "$OPTARG" == "pod" ]; then
				domain="http://127.0.0.1:9081"
				dns_resolver=""
      else
        echo "Invalid environment specified"
        exit 1
      fi
      ;;
    t)
      max_time="$OPTARG"
      ;;
	:)
      echo "Missing argument for option -$OPTARG"
      exit 1
      ;;
    *)
      show_script_usage
      ;;
  esac
done


echo "===============================STEP1===================================="
echo "Getting Access Token"
echo "========================================================================"
token=$(get_access_token)
echo "Token is: $token"


while true  # infinite loop breaks if and error is received in check_response
do


  # generate a random number between 3 and 30 (imitate human behaviour)
#  random_number=$(shuf -i 0-3 -n 1)
#  echo "sleeping before first call $random_number secs"
#  sleep $random_number

#  echo "===============================STEP2===================================="
  # Variables
#  no_db_endpoint="categories"
#  no_db_url=$domain$version$no_db_endpoint
  # STEP INFO
#  current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
#  echo $current_datetime
#  echo "* Full No DB involved URL $no_db_url"
#  echo "* Calling Comment Categories API (No DB consumption)"
#  echo "========================================================================"
#  response=$(curl -s --max-time "$max_time" -H "Authorization: Bearer $token" -w "%{http_code}" $dns_resolver "$no_db_url")
#  echo $response
#  check_response
#  check_result=$?

#  if [ $check_result -ne 0 ]; then
#    current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
#    echo $current_datetime
#    echo "...aborting, error detected"
#    exit 1
#  fi

#  echo "===============================STEP3===================================="

  # generate a random number between 3 and 30 (imitate human behaviour)
#  random_number=$(shuf -i 0-2 -n 1)
#  echo "sleeping before second call $random_number secs"
#  sleep $random_number

  # Variables
#  db_endpoint="patient/$patient_id/relevantinformation"
#  db_url=$domain$version$db_endpoint
  # STEP INFO
#  current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
#  echo $current_datetime
#  echo "* Full Db involved URL $db_url"
#  echo "========================================================================"
#  echo "Calling Patient Relevant Information API (DB consumption)"
#  response=$(curl -s --max-time "$max_time" -H "Authorization: Bearer $token" -w "%{http_code}" $dns_resolver "$db_url")
#  echo $response
#  check_response
#  check_result=$?

#  if [ $check_result -ne 0 ]; then
#    current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
#    echo $current_datetime
#    echo "...aborting, error detected"
#    exit 1
#  fi

  echo "===============================STEP4===================================="

  # Variables
  db_endpoint="patient/relevantinformation"
  db_url=$domain$version$db_endpoint

  # generate a random number between 3 and 30 (imitate human behaviour)
  random_number=$(shuf -i 0-3 -n 1)
  echo "sleeping before first call $random_number secs"
  sleep $random_number


  # STEP INFO
  current_datetime=$(date +%Y-%m-%d\ %H:%M:%S)
  echo $current_datetime
  echo "* Update DB involved URL $db_url"
  echo "========================================================================"
  echo "Calling Updating Relevant Information API (DB update)"
  echo $json_data
  response=$(curl -s --max-time "$max_time" -X POST -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$json_data" -w "%{http_code}" $dns_resolver "$db_url")
  echo $response
  check_response
  check_result=$?

  if [ $check_result -ne 0 ]; then
    current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
    echo "*****************"
    echo $current_datetime
    echo "...error detected"
    echo "*****************"
    # exit 1
  fi

done