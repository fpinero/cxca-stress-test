#!/bin/bash


host="hotfix.stage.screening.navify.com"
domain=""
version="/api/v1/"
auth_token_endpoint="/auth/realms/cxca-cockpit/protocol/openid-connect/token"
patient_id="46d9dd32-fcd7-431c-8a1e-20c22005e922"
max_time=150
dns_resolver=""
loop=6000

idp_client_secret='M:vaW-(Eqk(fF3kivgXUryG*$2{C1sa['
idp_username='devops'
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
			echo "HTTP Error 499 raised!"
		elif [[ $status_code == 5*  || $status_code == 4* ]]; then
			echo "HTTP Error $status_code"
			echo "Error response: $response"
		elif [[ $status_code == 2* ]]; then
			echo "Response received with HTTP $status_code"
		else
			echo "No response obtained in $max_time seconds"
		fi
	else
	  echo "No response obtained in $max_time seconds"
	fi
}

# No operator present
if [[ ! $@ =~ \-e\ .+ ]]; then
	show_script_usage
fi


while getopts "e:t:l:" opt; do
  case $opt in
    e)
      if [ "$OPTARG" == "cloudflare" ]; then
				domain="https://$host"
				dns_resolver=""
			elif [ "$OPTARG" == "loadbalancer" ]; then
				domain="https://$host"
				dns_resolver=" --resolve $host:443:3.73.165.110 "
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
    l)
	    loop="$OPTARG"
	    echo loop is ${loop}
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

echo loop is going to be "$loop" cycles, can be changed with the -l flag


echo "===============================STEP1===================================="
echo "Getting Access Token"
echo "========================================================================"
token=$(get_access_token)
echo "Token is: $token"

for ((i=1; i<=loop; i++))
do

  echo "===============================STEP2===================================="
  # Variables
  no_db_endpoint="categories"
  no_db_url=$domain$version$no_db_endpoint
  # STEP INFO
  current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
  echo $current_datetime
  echo "* Full No DB involved URL $no_db_url"
  echo "* Calling Comment Categories API (No DB consumption)"
  echo "========================================================================"
  response=$(curl -s --max-time "$max_time" -H "Authorization: Bearer $token" -w "%{http_code}" $dns_resolver "$no_db_url")
  echo $response
  check_response

  echo "===============================STEP3===================================="
  # Variables
  db_endpoint="patient/$patient_id/relevantinformation"
  db_url=$domain$version$db_endpoint
  # STEP INFO
  current_datetime=`date +%Y-%m-%d\ %H:%M:%S`
  echo $current_datetime
  echo "* Full Db involved URL $db_url"
  echo "========================================================================"
  echo "Calling Patient Relevant Information API (DB consumption)"
  response=$(curl -s --max-time "$max_time" -H "Authorization: Bearer $token" -w "%{http_code}" $dns_resolver "$db_url")
  echo $response
  check_response

done