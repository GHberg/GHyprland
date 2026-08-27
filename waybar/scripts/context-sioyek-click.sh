#!/bin/bash
# Execute Sioyek highlight command
# Usage: context-sioyek-click.sh [color_key]

COLOR_KEY="${1:-a}"

# Send highlight command to Sioyek
sioyek --execute-command add_highlight --execute-command-data "$COLOR_KEY" 2>/dev/null
