#!/bin/bash

DEFAULT_OUTPUT=~/.fonts

declare -a src_fonts
output=$DEFAULT_OUTPUT

usage() {
	echo "Usage"
}

help() {
	cat <<- EOF
		Usage:
		  -s, --source: source path, all referred files will be fetched relative to this path
		  -o, --output: installation directory
		  -i, --isolate: create directories for fonts; defaults to false
		  -f, --flatten: copy font files without preserving the original directory sturcture; defaults to false
		  -h, --help: shows this message
		  -v, --verbose: verbose mode: defaults to false
	EOF
}

install_font() {
	local font="$1"
	local path=$font

	if [ -n $source ]; then
		path="${source}/${font}"
	fi

	local name
	local type

	if [[ "$font" =~ .*\.zip ]]; then
		name=${font%*.zip}
		type="zip"
	elif [[ "$font" =~ .*\.tar\.gz ]]; then
		name=${font%*.tar.gz}
		type="gz"
	elif [[ "$font" =~ .*\.tar\.bz ]]; then
		name=${font%*.tar.bz}
		type="bz"
	else
		echo "${font}: unrecognized format."
	fi

	name="$(basename $name)"

	if (( $isolate )); then
		if [ -z $name ]; then
			echo "Name is empty: can't create directoy."
			exit 1
		fi

		path="${output}/${name}"
		temp_path="/tmp/${name}"
		mkdir -p "$path" "$temp_path" 2> /dev/null || echo "Can't create directory for ${name}."
	fi

	case $type in
		zip)
			unzip "$font" -d "$temp_path"
			;;
		gz | bz)
			tar -xvzf "$font" -C "$temp_path"
			;;
	esac

	if (( $flatten )); then
		cp -r ${temp_path}/**/*.ttf ${temp_path}/**/*.otf "$path" 2> /dev/null
	else
		mv ${temp_path}/* "$path"
		find "$path" -type f ! \( -name "*.ttf" -or -name "*.otf" \) -delete
		find "$path" -type d -empty -delete
	fi

	rm -rf "$temp_path"
}

while [ -n "$1" ]; do
	case "$1" in
		-s | --source)
			shift
			if [ ! -d "$1" ]; then
				echo "Path not found: $1"
				exit 1
			fi

			source=$1
			;;
		-o | --output)
			shift
			output=$1
			;;
		-i | --isolate)
			isolate=1
			;;
		-f | --flatten)
			flatten=1
			;;
		-h | --help)
			help
			exit 0
			;;
		-v | --verbose)
			verbose=1
			;;
		*)
			if [[ "$1" =~ --?.* ]]; then
				echo "$1: unrecognized flag."
				usage
				exit 1
			fi

			if [ ! -e "$1" ]; then
				echo "Font not found: $1."
				exit 1
			fi
			
			src_fonts+=("$1")
			;;
	esac

	shift
done

mkdir -p "$output" 2> /dev/null || echo "Can't create output directory."

for font in "${src_fonts[@]}"; do
	install_font $font
done
