#!/usr/bin/env bash

d() {

	declare -r D_NAME="${D_NAME:-${FUNCNAME[0]}}"
	declare -r D_CONFIG_DIR="${D_CONFIG_DIR:-$HOME}"
	declare -r D_FAV_DIRS_FILE="${D_FAV_DIRS_FILE:-$D_CONFIG_DIR/.d}"
	if [[ ! -v D_SELECT_ONE ]]; then
		declare -ra D_SELECT_ONE=('fzf' '--tac')
	fi
	if [[ ! -v D_SELECT_MANY ]]; then
		declare -ra D_SELECT_MANY=('fzf' '--tac' '--multi')
	fi
	if [[ ! -v D_PARENTS ]]; then
		declare -ri D_PARENTS=0
	else
		declare -ri D_PARENTS=1
	fi

	____d_normalize() {
		sed '/^$/d' | sort | uniq
	}

	__d_help() {
		if [[ $# -gt 0 ]]; then
			echo "$0: error: no args accepted" >&2
			return 1
		fi
		cat << EOF
$D_NAME - fav dirs

syntax:
	$D_NAME [<COMMAND> [OPT...] [--] [ARG...]]

commands:
	add [-f|--force] [dir...]
		- add \`pwd\` or directories to the fav dirs file

	clear [-f|--force]
		- clear the fav dirs file

	config
		- show effective configuration

EOF
		if [[ ! -v __D_EXECUTED ]]; then
			cat << EOF
	cd [-p|--parents]
		- change current directory (default)
		  has no \`cd\` effect if ${BASH_SOURCE[0]} is executed as a script (not \`source\`d)

EOF
		fi
		cat << EOF
	edit
		- edit the fav dirs file

	ls
		- list the fav dirs file

	prune
		- prune missing directories from the fav dirs file

	rm [dir...]
		- remove directories from the fav dirs file

	help
		- show this help
EOF
	}

	__d_add() {
		declare -i FORCE=0
		while [[ $# -gt 0 ]]; do
			case "$1" in
			'-f'|'--force')
				FORCE=1
				;;
			'--')
				shift
				break
				;;
			*)
				break
				;;
			esac
			shift
		done
		if [[ $# -eq 0 ]]; then
			set -- "$(pwd)"
		fi
		declare DIR
		for DIR; do
			if [[ FORCE -eq 0 && ! -d "$DIR" ]]; then
				if [[ ! -e "$DIR" ]]; then
					echo "$D_NAME: error: $DIR does not exist" >&2
				else
					echo "$D_NAME: error: $DIR is not a directory" >&2
				fi
				return 1
			fi
			DIR="$(readlink -f -- "$DIR")"
			printf '%s\n' "$DIR"
			echo "add $DIR" >&2
		done >> "$D_FAV_DIRS_FILE"
		declare -r TMP="$(mktemp)"
		cp "$D_FAV_DIRS_FILE" "$TMP"
		____d_normalize < "$TMP" > "$D_FAV_DIRS_FILE"
		rm -f "$TMP"
	}

	__d_cd() {
		if [[ -v __D_EXECUTED ]]; then
			echo "$0: warn: the cd command may have no effect if started in limited (script) mode" >&2
		fi
		declare -i PARENTS=0
		if [[ $# -gt 0 ]] && [[ "$1" == '-p' || "$1" == '--parents' ]]; then
			PARENTS=1
			shift
		fi
		if [[ $# -gt 0 ]]; then
			echo "$D_NAME: error: no args accepted" >&2
			return 1
		fi
		if [[ D_PARENTS -ne 0 ]]; then
			PARENTS=1
		fi
		declare DIR
		if [[ $PARENTS -eq 0 ]]; then
			DIR="$(sort < "$D_FAV_DIRS_FILE" | uniq | "${D_SELECT_ONE[@]}")"
		else
			DIR="$(
				{
					printf '%s\n' '/'
					while read -r DIR; do
						while [[ -n "$DIR" ]]; do
							printf '%s\n' "$DIR"
							DIR="${DIR%/*}"
						done
					done
				 } < "$D_FAV_DIRS_FILE" | sort | uniq | "${D_SELECT_ONE[@]}"
			)"
		fi
		cd "$DIR"
		if [[ -v __D_EXECUTED ]]; then
			pwd >&2
		fi
	}

	__d_clear() {
		if [[ $# -ne 1 ]] || [[ "$1" != '-f' && "$1" != '--force' ]]; then
			echo "$D_NAME: error: must be confirmed with the -f (--force) switch" >&2
			return 1
		fi
		: > "$D_FAV_DIRS_FILE"
	}

	__d_config() {
		printf '%s=%q\n' \
			'D_CONFIG_DIR' "$D_CONFIG_DIR" \
			'D_FAV_DIRS_FILE' "$D_FAV_DIRS_FILE" \
			'D_PARENTS' "$D_PARENTS" \
			'D_SELECT_MANY' "${D_SELECT_MANY[*]}" \
			'D_SELECT_ONE' "${D_SELECT_ONE[*]}"
	}

	__d_edit() {
		if [[ $# -gt 0 ]]; then
			echo "$D_NAME: error: no args accepted" >&2
			return 1
		fi
		if [[ -v VISUAL && -n "$VISUAL" ]]; then
			declare -r EDITOR="$VISUAL"
		elif [[ -v EDITOR && -n "$EDITOR" ]]; then
			:
		elif IFS= read -r EDITOR < <(which editor) && [[ -v EDITOR && -n "$EDITOR" ]]; then
			:
		elif [[ -e '/usr/bin/editor' ]]; then
			declare -r EDITOR='/usr/bin/editor'
		else
			declare -r EDITOR='ed'
		fi
		"${EDITOR}" "$D_FAV_DIRS_FILE"
		declare -r TMP="$(mktemp)"
		cp "$D_FAV_DIRS_FILE" "$TMP"
		____d_normalize < "$TMP" > "$D_FAV_DIRS_FILE"
		rm -f "$TMP"
	}

	__d_ls() {
		if [[ $# -gt 0 ]]; then
			echo "$D_NAME: error: no args accepted" >&2
			return 1
		fi
		cat "$D_FAV_DIRS_FILE"
	}

	__d_prune() {
		if [[ $# -gt 0 ]]; then
			echo "$D_NAME: error: no args accepted" >&2
			return 1
		fi
		declare -r TMP="$(mktemp)"
		declare ORIG_DIR
		declare DIR
		while read -r ORIG_DIR; do
			DIR="$(readlink -f -- "$ORIG_DIR")"
			if [[ ! -e "$DIR" ]]; then
				echo "prune $ORIG_DIR" >&2
				continue
			fi
			if [[ ! -d "$DIR" ]]; then
				echo "prune $ORIG_DIR" >&2 # TODO consider indicating a removal for a non-directory
				continue
			fi
			printf '%s\n' "$DIR"
		done < "$D_FAV_DIRS_FILE" > "$TMP"
		____d_normalize < "$TMP" > "$D_FAV_DIRS_FILE"
		rm -f "$TMP"
	}

	__d_rm() {
		declare -A RM_INDEX_FILE
		declare DIR
		if [[ $# -eq 0 ]]; then
			while IFS= read -r DIR; do
				RM_INDEX_FILE["$DIR"]=1
			done < <("${D_SELECT_MANY[@]}" < "$D_FAV_DIRS_FILE")
		else
			for DIR; do
				DIR="$(readlink -f -- "$DIR")"
				RM_INDEX_FILE["$DIR"]=1
			done
		fi
		if [[ ${#RM_INDEX_FILE[@]} == 0 ]]; then
			return
		fi
		declare -r TMP="$(mktemp)"
		while IFS= read -r DIR; do
			if [[ -n "${RM_INDEX_FILE[$DIR]+TO_RM}" ]]; then
				echo "rm $DIR" >&2
				unset "RM_INDEX_FILE[$DIR]"
				continue
			fi
			printf '%s\n' "$DIR"
		done < "$D_FAV_DIRS_FILE" > "$TMP"
		____d_normalize < "$TMP" > "$D_FAV_DIRS_FILE"
		rm -f "$TMP"
	}

	if [[ $# -eq 0 ]]; then
		set -- 'cd'
	fi

	declare -r COMMAND="${1?no command}"
	shift

	case "$COMMAND" in
	'add'|'cd'|'clear'|'config'|'edit'|'help'|'ls'|'prune'|'rm')
		__d_"$COMMAND" "$@"
		;;
	*)
		echo "$D_NAME: error: unrecognized command: $COMMAND" >&2
		return 1
		;;
	esac
}

if ! (return 2> /dev/null); then
	set -TEeuo pipefail
	__D_EXECUTED='' D_NAME="$0" d "$@"
fi
