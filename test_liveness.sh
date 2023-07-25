#!/bin/bash

max_time=250
domain=""
application_health_liveness="/actuator/health/liveness"
application_health_readiness="/actuator/health/readiness"
application_thread_dump="/actuator/threaddump"
application_metrics_prometheus="/actuator/prometheus"

show_script_usage() {
	echo "Usage: ./call_application_metrics.sh -e <environment> -t <max_response_time>"
	echo "-e: Environtment values -> hotfix2"
	echo "-t: Max Time for response in seconds. 250 by default"
	exit 1
}

check_response() {

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
			echo "$response"
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


while getopts "e:t:" opt; do
  case $opt in
    e)
      if [ "$OPTARG" == "hotfix2" ]; then
        domain="https://hotfix2.stage.screening.navify.com"
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

echo "Calling Health Liveness"
url1=$domain$application_health_liveness
response=$(curl -s --max-time "$max_time" -w "%{http_code}" "$url1")
check_response

echo "Calling Health Readiness"
url2=$domain$application_health_readiness
response=$(curl -s --max-time "$max_time" -w "%{http_code}" "$url2")
check_response

mkdir -p log_metrics

echo "Calling Thread Dump"
url3=$domain$application_thread_dump
filename1="log_metrics/$(date -u +"%FT-%H-%M-%SZ")_threaddump.log"
response=$(curl -s --max-time "$max_time" "$url3" > $filename1)
echo "Generated Thread Dump at $filename1"

echo "Calling Metrics through Prometheus"
url4=$domain$application_metrics_prometheus
filename2="log_metrics/$(date -u +"%FT-%H-%M-%SZ")_prometheus_metrics.log"
response=$(curl -s --max-time "$max_time" "$url4" > $filename2)
echo "Generated Metrics through Prometheus at $filename2"