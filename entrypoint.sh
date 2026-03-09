#!/bin/bash

/usr/sbin/sshd -D & \
exec usr/local/bin/docker-entrypoint.sh "$@"
