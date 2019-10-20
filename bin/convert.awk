#! /usr/bin/awk -f

# name,time,exchange,pair,open,close,high,low,volume

BEGIN {
  FS=","
  OFS=","
  print "# DML"
  print "# CONTEXT-DATABASE: arke_development"
}

NR<=1 { next }

{ printf "candles_1m,exchange=%s,market=%s open=%s,high=%s,low=%s,close=%s,volume=%s %d\n", $3, $4, $5, $7, $8, $6, $9, $2 }
