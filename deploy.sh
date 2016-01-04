#!/bin/bash
MARATHON=http://192.168.50.100:8080

curl -X POST $MARATHON/v2/apps -d @$1 -H "Content-type: application/json"

