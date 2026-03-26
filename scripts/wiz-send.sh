#!/bin/bash
WIZ_IP="${WIZ_BULB_IP:-192.168.1.248}"
echo -n "$1" | nc -u -w1 "$WIZ_IP" 38899
