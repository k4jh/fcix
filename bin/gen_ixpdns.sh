#!/bin/bash
#
# Generate DNS zone records for participants
# Kenneth Finnegan, 2019
#
# On the primary nameserver, schedule this script to run by crontab:
#   12 */6 * * *    /opt/fcix/bin/gen_ixpdns.sh
#
# In the /etc/bind/named.conf.local configure these zones:
#   zone "ixp.fcix.net." {
#           type master;
#           file "/etc/bind/zones/db.ixp.fcix.net";
#   };
#   
#   zone "238.80.206.in-addr.arpa." {
#           type master;
#           file "/etc/bind/zones/db.206.80.238";
#   };
#   
#   zone "1.9.0.0.4.0.5.0.1.0.0.2.ip6.arpa." {
#           type master;
#           file "/etc/bind/zones/db.2001.504.91";
#   };


SRC_DIR=/opt/fcix
ZONEDIR="/etc/bind/zones"
NSPRIMARY="ns1.phirephly.design."

SOAPOLICY="\$TTL 1h ; Default TTL
@	IN	SOA	$NSPRIMARY	noc.fcix.net. (
				`date '+%Y%m%d%H'`	; Serial
				15m	; Refresh
				5m	; Retry
				1w	; Expire
				1m )	; Negative Cache TTL

@	IN	NS	$NSPRIMARY"


cd $SRC_DIR
/usr/bin/git pull

#
# Generate forward zone to produce an A and AAAA record for each ASnnnn.ixp.fcix.net record
#
cat >$ZONEDIR/db.ixp.fcix.net <<EOF
;
; FCIX Forward DNS 
; --- DO NOT EDIT THIS FILE ---
; --- THIS IS AUTOMATICALLY GENERATED ---
;

$SOAPOLICY

EOF
tail -n +2 participants.tsv | \
awk -F '\t' '{print "AS" $3 ".ixp.fcix.net.\tIN  A  206.80.238." $1 "\nAS" $3 ".ixp.fcix.net.\tIN  AAAA  2001:504:91::" $1 }' >>$ZONEDIR/db.ixp.fcix.net

cat >>$ZONEDIR/db.ixp.fcix.net <<EOF
RS1.ixp.fcix.net.     IN  A  206.80.238.253
RS1.ixp.fcix.net.     IN  AAAA  2001:504:91::253
RS2.ixp.fcix.net.     IN  A  206.80.238.254
RS2.ixp.fcix.net.     IN  AAAA  2001:504:91::254

EOF

#
# Generate reverse PTR zone for IPv4
#
cat >$ZONEDIR/db.206.80.238 <<EOF
;
; FCIX IPv4 Reverse DNS 
; --- DO NOT EDIT THIS FILE ---
; --- THIS IS AUTOMATICALLY GENERATED ---
;

$SOAPOLICY

EOF

tail -n +2 participants.tsv | \
awk -F '\t' '{print $1 "\tIN  PTR  AS" $3 ".ixp.fcix.net."}' >>$ZONEDIR/db.206.80.238

cat >>$ZONEDIR/db.206.80.238 <<EOF
253     IN  PTR  RS1.ixp.fcix.net.
254     IN  PTR  RS2.ixp.fcix.net.

EOF


#
# Generate reverse PTR zone for IPv6
#
cat >$ZONEDIR/db.2001.504.91 <<EOF
;
; FCIX IPv6 Reverse DNS 
; --- DO NOT EDIT THIS FILE ---
; --- THIS IS AUTOMATICALLY GENERATED ---
;

$SOAPOLICY

EOF

tail -n +2 participants.tsv | \
awk -F '\t' 'function reverse_host_addr(addr)
{
  p = ""
  for(i=1; i <= length(addr); i++) { p = substr(addr, i, 1) "." p }
  return p 
}

{print reverse_host_addr(sprintf("%04d", $1)) "0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.9.0.0.4.0.5.0.1.0.0.2.ip6.arpa.\tIN  PTR  AS" $3 ".ixp.fcix.net."}' >>$ZONEDIR/db.2001.504.91


cat >>$ZONEDIR/db.2001.504.91 <<EOF
3.5.2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.9.0.0.4.0.5.0.1.0.0.2.ip6.arpa.       IN  PTR  RS1.ixp.fcix.net.
4.5.2.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.1.9.0.0.4.0.5.0.1.0.0.2.ip6.arpa.       IN  PTR  RS2.ixp.fcix.net.

EOF

/usr/sbin/service bind9 reload
