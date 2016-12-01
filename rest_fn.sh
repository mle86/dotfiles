#!/bin/sh


rest_auth () {
	local progname='rest_auth'
	local usage="usage: $progname [USERNAME:PASSWORD]\nusage: $progname -   (to clear)\n"
	local current="$MY_REST_AUTH_DATA"
	local current_username="${current%%:*}"
	local setto=

	if [ $# -lt 1 ]; then
		printf "$usage"  >&2
		[ -n "$current" ] && printf '[1;38;5;48m✔[0m Found rest auth data (username: [1m%s[0m)\n' "$current_username"
		[ -n "$current" ] || printf '[1;38;5;124m✕[0m Currently no rest auth data set.\n'
		echo ""
		return 0
	elif [ $# -eq 1 ]; then
		setto="$1"
	elif [ $# -eq 2 ]; then
		setto="$1:$2"
	else
		printf "$usage\n"  >&2
		return 1
	fi

	case "$setto" in
		""|"-")
			unset MY_REST_AUTH_DATA
			return 0 ;;
		*":"*)
			export MY_REST_AUTH_DATA="$setto"
			return 0 ;;
		*)
			printf "$usage\n"  >&2
			return 1 ;;
	esac
}

rest_header () {
	local progname='rest_header'
	local usage="usage: $progname HEADERNAME [VALUE]\n"
	local MAX_HEADERS=20
	local c1='[1m'
	local c0='[0m'

	if [ $# -lt 1 ]; then
		printf "$usage\n"  >&2
		local found=
		for h in $(seq 1 $MAX_HEADERS); do
			eval "[ -n \"\$MY_REST_HEADER_${h}\" ] && found=yes && printf \"${c1}%s${c0}: %s\n\" \"\$MY_REST_HEADER_${h}\" \"\$MY_REST_HEADER_VALUE_${h}\""
		done
		[ "$found" ] && echo "" || true
	elif [ $# -eq 1 ]; then
		for h in $(seq 1 $MAX_HEADERS); do
			eval "[ \"\$MY_REST_HEADER_${h}\" = \"\$1\" ] && unset MY_REST_HEADER_${h} && return"
		done
	else
		local next=
		for h in $(seq 1 $MAX_HEADERS); do
			eval "
				if [ -z \"\$MY_REST_HEADER_${h}\" ]; then
					[ -z \"\$next\" ] && next=${h} ;
				elif [ \"\$MY_REST_HEADER_${h}\" = \"\$1\" ]; then
					export MY_REST_HEADER_VALUE_${h}=\"\$2\" ;
					return ;
				fi "
		done
		if [ -n "$next" ]; then
			eval "
				export MY_REST_HEADER_${next}=\"\$1\" ;
				export MY_REST_HEADER_VALUE_${next}=\"\$2\" ; "
			return 0
		else
			echo "too many" >&2
			return 1
		fi
	fi
}

