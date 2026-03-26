#!/bin/bash
DIR="$(dirname "$0")"
"$DIR/wiz-send.sh" '{"id":1,"method":"setPilot","params":{"state":false}}'
