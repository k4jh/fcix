#!/bin/bash
#
# gen_routeserver_clients.sh - Generates clients yml manifest for arouteserver
# Kenneth Finnegan, 2018

cat <<EOF >routeserver/clients.yml
# DO NOT EDIT THIS FILE - Automatically generated

clients:

EOF

tail -n +2 participants.tsv | \
awk -F '\t' '{print "  - asn: " $3 "\n    ip:\n    - \"206.80.238." $1 "\"\n    - \"2001:504:91::" $1 "\""}' >> routeserver/clients.yml
