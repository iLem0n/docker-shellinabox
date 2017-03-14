#!/bin/bash

set -e

hex()
{
	openssl rand -hex 8
}

echo "Preparing container .."
COMMAND="/usr/bin/shellinaboxd --debug --no-beep -u shellinabox -g shellinabox -c /var/lib/shellinabox -p ${SIAB_PORT} --user-css ${SIAB_USERCSS}"

if [ "$SIAB_PKGS" != "none" ]; then
	set +e
        dnf install -y ${SIAB_PKGS}
        dnf clean all
	set -e
fi

if [ "$SIAB_SSL" != "true" ]; then
	COMMAND+=" -t"
fi

if [ "${SIAB_ADDUSER}" == "true" ]; then
	sudo=""
	if [ "${SIAB_SUDO}" == "true" ]; then
		sudo="-G wheel"
	fi
	if [ -z "$(getent group ${SIAB_GROUP})" ]; then
		groupadd -g ${SIAB_GROUPID} ${SIAB_GROUP}
	fi
	if [ -z "$(getent passwd ${SIAB_USER})" ]; then
		useradd -u ${SIAB_USERID} -g ${SIAB_GROUPID} -s ${SIAB_SHELL} -d ${SIAB_HOME} -m ${sudo} ${SIAB_USER}
		if [ "${SIAB_PASSWORD}" == "putsafepasswordhere" ]; then
			SIAB_PASSWORD=$(hex)
			echo "Autogenerated password for user ${SIAB_USER}: ${SIAB_PASSWORD}"
		fi
		echo "${SIAB_USER}:${SIAB_PASSWORD}" | chpasswd
		unset SIAB_PASSWORD
	fi
fi

for service in ${SIAB_SERVICE}; do
	COMMAND+=" -s ${service}"
done

if [ "$SIAB_SCRIPT" != "none" ]; then
	set +e
	curl -s -k ${SIAB_SCRIPT} > /prep.sh
	chmod +x /prep.sh
	echo "Running ${SIAB_SCRIPT} .."
	/prep.sh
	set -e
fi

echo "Starting container .."
if [ "$@" = "shellinabox" ]; then
	echo "Executing: ${COMMAND}"
	exec ${COMMAND}
else
	echo "Not executing: ${COMMAND}"
	echo "Executing: ${@}"
	exec $@
fi
