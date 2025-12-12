#!/bin/bash
sleep 10
while true ; do sh /api/collect-coverage.sh & sleep 5; done
