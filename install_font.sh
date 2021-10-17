#!/bin/bash

# ==============================================================================
# Declarations
# ==============================================================================
OUTPUT_DIRECTORY=~/.fonts

declare -a font_sources

output_directory=$OUTPUT_DIRECTORY

isolate=0
keep=0
exclude=0
force=0
verbose=0

# ==============================================================================
# Functions
# ==============================================================================
error() {
	echo "error -- $1"
	help
	exit 1
}

help() {
	cat <<- EOF
		usage: finst [option [arg]] [font]

		run 'finst --help' for more info.
	EOF
}

usage() {
	cat <<- EOF
		usage: finst [option [arg]] [font]

		options:
		  -s, --source		specify source directory
		  -o, --output		specify installation directory
		  -i, --isolate		install fonts in distinct directories
		  -k, --keep		keep original directory structure
		  -x, --exclude		exclude non-font files
		  -f, --force		overwrite existing files without confirmation
		  -h, --help		show this message
	EOF
}

ensure_directory() {
	if ! mkdir -p "$1" 2> /dev/null; then
		error "failed to create directory: '$1'"
	fi
}

check_file() {
	if [ -f "$1" ]; then
		if (( ! force )); then
			read -rp "$1 exists: [o]verwrite/[s]kip? "

			if [ "$REPLY" != "o" ]; then
				return
			fi
		fi

		rm -rf "$1"
	fi
}

install_font() {
	local font_file="$1"

	if [ ! -f "$font_file" ]; then
		error "file not found: $font_file"
	elif [[ ! "$font_file" =~ .*\.zip ]]; then
		error "invalid file type: $font_file"
	fi

	local font_name=${font_file%*.zip}
	font_name=$(basename "$font_name")
	if [ -z "$font_name" ]; then
		error "can't install unnamed font"
	fi

	# fonts to install
	# declare -a found_fonts
	if (( exclude )); then
		found_fonts=$(unzip -Z1 "$font_file" "*.ttf" "*.otf" 2> /dev/null)
	else
		found_fonts=$(unzip -Z1 "$font_file" 2> /dev/null)
	fi

	local font_output=$output_directory

	if (( isolate )); then
		font_output+="/$font_name"

		if [ -d "$font_output" ]; then
			if (( ! force )); then
				read -rp "$font_output exists. [o]verwrite/[a]ppend? "

				if [ "$REPLY" = "o" ]; then
					rm -rf "$font_output"
				fi
			else
				rm -rf "$font_output"
			fi
		fi

		ensure_directory "$font_output"
	else
		for font in ${found_fonts[@]}; do
			if (( ! keep )); then
				check_file "$font_output/$(basename "$font")"
			else
				check_file "$font_output/$font"
			fi
		done
	fi

	local keep_flag="-j"
	if (( keep )); then
		keep_flag=""
	fi

	if (( exclude )); then
		unzip -qq -n $keep_flag "$font_file" "*.ttf" "*.otf" -d "$font_output" 2> /dev/null
	else
		unzip -qq -n $keep_flag "$font_file" -d "$font_output" 2> /dev/null
	fi
}

process_params() {
	while [ -n "$1" ]; do
		local param=$1

		case $param in
		-s | --source)
			shift

			if [ -z "$1" ]; then
				error "missing input directory"
			fi
			source_directory=$1
			;;
		-o | --output)
			shift

			if [ -z "$1" ]; then
				error "missing output directory"
			fi
			output_directory=$1
			;;
		-i | --isolate) isolate=1 ;;
		-k | --keep) keep=1 ;;
		-x | --exclude) exclude=1 ;;
		-f | --force) force=1 ;;
		-h | --help) usage; exit 0 ;;
		*)
			local flag=${param//-/}

			if [[ $param =~ ^-[ikxfh]{2,}$ ]]; then
				flag_combination=${param#-}

				for ((i = 0; i < ${#flag_combination}; i++)); do
					process_params "-${flag_combination:$i:1}"
				done
			elif [[ $param =~ ^-[^-]{2,}$ ]]; then
				error "invalid flag combination; '$flag'"
			elif [[ $param =~ ^-.*$ ]]; then
				error "unrecognized flag: '$flag'"
			else
				font_sources+=("$param")
			fi
			;;
		esac

		shift
	done
}

process_params "$@"

if (( ${#font_sources[@]} == 0 )); then
	error "no fonts specified."
fi

ensure_directory "$output_directory"

for font in "${font_sources[@]}"; do
	if [ -n "$source_directory" ]; then
		install_font "$source_directory/$font"
	else
		install_font "$font"
	fi
done
