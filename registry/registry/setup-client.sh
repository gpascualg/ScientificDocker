#!/bin/sh
cp server.crt /etc/docker/certs.d/registry.damnserver.com:443/ca.crt
cp server.crt /usr/local/share/ca-certificates/registry.damnserver.com.crt
