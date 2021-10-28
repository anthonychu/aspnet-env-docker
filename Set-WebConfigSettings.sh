#!/bin/bash

# Linux version of https://anthonychu.ca/post/overriding-web-config-settings-environment-variables-containerized-aspnet-apps/

webConfig=$1

## Override app settings and connection string with environment variables

appSettingPrefix="APPSETTING_"
appSettingPrefixForCut="${appSettingPrefix}a"
connectionStringPrefix="CONNSTR_"
connectionStringPrefixForCut="${connectionStringPrefix}a"

env | while IFS= read -r line; do
	value=${line#*=}
	name=${line%%=*}

	if [[ $name == $appSettingPrefix* ]] ; then
		# substring
		key=$( echo "$name" | cut -c${#appSettingPrefixForCut}- )

		xmlstarlet ed --inplace -u "/configuration/appSettings/add[@key='$key']/@value" -v $value $webConfig

		echo "Replaced appSetting $key $value"
	fi

	if [[ $name == $connectionStringPrefix* ]] ; then
		# substring
		key=$( echo "$name" | cut -c${#connectionStringPrefixForCut}- )

		xmlstarlet ed --inplace -u "/configuration/connectionStrings/add[@name='$key']/@connectionString" -v $value $webConfig

		echo "Replaced connectionString $key"
	fi
done
