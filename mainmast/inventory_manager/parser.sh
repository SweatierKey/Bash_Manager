#!/usr/bin/env bash
# parsing.sh
# parsa l'inventory file.

source "$(dirname "${BASH_SOURCE[0]}")/inventory_parsing_utilities.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

strip_inventory() {
	local inventory_file="$1"
	while IFS= read -r line; do
		line=$(trim "$line")
		if is_line_empty "$line" || is_line_comment "$line"; then continue; fi
		[[ -n "$line" ]] && echo "$line"
	done < "$inventory_file"
}


