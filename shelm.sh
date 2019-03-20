#!/bin/sh
#
# SHelm -- A wrapper for using helm with TLS
#
# Copyright 2019 Noah Hummel
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CONFIG_DIRECTORY="${HOME}/.helm_identities"

ensure_config_directory_exists()
{
	if [ ! -d "$CONFIG_DIRECTORY" ]; then
		mkdir "$CONFIG_DIRECTORY"
	fi
}

get_identity_dir()
{
	myId="$1"
	echo "${CONFIG_DIRECTORY}/${myId}"
}

get_identity_key()
{
	myId="$1"
	echo "${CONFIG_DIRECTORY}/${myId}/client.key"
}

get_identity_cert()
{
	myId="$1"
	echo "${CONFIG_DIRECTORY}/${myId}/client.crt"
}

get_identity_ca_cert()
{
	myId="$1"
	echo "${CONFIG_DIRECTORY}/${myId}/ca.crt"
}

add_identity()
{
	keyOrCertFullPath=$1
	caCertFullPath=$2
	keyOrCertName="$(basename $keyOrCertFullPath)"
	directory="$(dirname keyOrCertFullPath)"
	myId="${keyOrCertName%.*}"

	if [ -d "${CONFIG_DIRECTORY}/${myId}" ]; then
		echo "The identity '${myId}' already exists."
		exit 1
	fi

	mkdir "${CONFIG_DIRECTORY}/${myId}"
	cp "${directory}/${myId}.crt" "${CONFIG_DIRECTORY}/${myId}/client.crt"
	cp "${directory}/${myId}.key" "${CONFIG_DIRECTORY}/${myId}/client.key"
	cp "${caCertFullPath}" "${CONFIG_DIRECTORY}/${myId}/ca.crt"
}

list_identities()
{
	identities=$(find "${CONFIG_DIRECTORY}" -maxdepth 1 -type d ! -path "${CONFIG_DIRECTORY}")
	if [ -z $identities ]; then
		return 0
	fi

	if [ -L "${CONFIG_DIRECTORY}/default" ]; then
		identities=$(echo "${identities}" | sed "s!$(get_identity_in_use)!$(get_identity_in_use) \[USED\]!g")
	fi

	echo $(echo "${identities}" | sed 's!.*/!!')
}

remove_identity()
{
	myId="$1"

	if [ ! -d "${CONFIG_DIRECTORY}/${myId}" ]; then
		echo "No such identity."
		exit 1
	fi

	if [ $(realpath "${CONFIG_DIRECTORY}/${myId}") = $(realpath $(get_identity_in_use)) ]; then
		rm "${CONFIG_DIRECTORY}/default"
	fi

	rm -rf "${CONFIG_DIRECTORY}/${myId}"
}

use_identity()
{
	if [ -L "${CONFIG_DIRECTORY}/default" ]; then
		unlink "${CONFIG_DIRECTORY}/default"
	fi

	if [ ! -d $(get_identity_dir "$1") ]; then
		echo "No such identity."
		exit 1
	fi

	ln -s $(get_identity_dir "$1") "${CONFIG_DIRECTORY}/default"
}

get_identity_in_use()
{
	if [ ! -L "${CONFIG_DIRECTORY}/default" ]; then
		return 0
	fi

	echo $(readlink -f "${CONFIG_DIRECTORY}/default")
}

do_the_helm()
{
	identity=$(basename $(get_identity_in_use))
	caCert=$(get_identity_ca_cert "${identity}")
	clientCert=$(get_identity_cert "${identity}")
	clientKey=$(get_identity_key "${identity}")
	echo helm $@ --tls \
		--tls-ca-cert "$caCert" \
		--tls-cert "${clientCert}" \
		--tls-key "${clientKey}"
}

case $1 in 
	identity)
		shift
		case $1 in
			add)
			shift
			add_identity $@
			;;
			list)
			list_identities
			;;
			use) 
			shift
			use_identity $@
			;;
			remove)
			shift
			remove_identity $@
			;;
			*)
			echo "Not a valid command!"
			exit 1
			;;
		esac
	;;
	* )
		do_the_helm $@
	;;
esac
