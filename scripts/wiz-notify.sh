#!/bin/bash
DIR="$(dirname "$0")"
"$DIR/wiz-send.sh" '{"id":1,"method":"setPilot","params":{"r":0,"g":100,"b":255,"dimming":100}}'
