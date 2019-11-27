#!/bin/sh
openssl req   -newkey rsa:4096 -nodes -sha256 -keyout server.key   -x509 -days 365 -out server.crt
cp server.crt /etc/docker/certs.d/registry.damnserver.com:443/ca.crt
cp server.crt /usr/local/share/ca-certificates/registry.damnserver.com.crt
