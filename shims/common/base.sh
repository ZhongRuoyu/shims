#!/bin/bash

shims_dir="$(dirname "$0")"
shim_basename="$(basename "$0")"
shim_realpath="$(realpath "$0")"

path_remove() {
    local IFS=":"
    local path_to_remove="$1"
    local path_variable="${2:-PATH}"
    local new_path=""
    local dir
    for dir in ${!path_variable}; do
        if [[ "$dir" != "$path_to_remove" ]]; then
            new_path="${new_path:+$new_path:}$dir"
        fi
    done
    export "$path_variable"="$new_path"
}

if [[ -n "$NO_SHIMS" ]]; then
    path_remove "$shims_dir"
    exec "$shim_basename" "$@"
fi

brew_prefix="$(brew --prefix)"

export PATH=""
export PATH="${PATH:+$PATH:}$shims_dir"
export PATH="${PATH:+$PATH:}$brew_prefix/bin"
export PATH="${PATH:+$PATH:}$brew_prefix/opt/binutils/bin"
export PATH="${PATH:+$PATH:}/usr/local/bin"
export PATH="${PATH:+$PATH:}/usr/local/sbin"
export PATH="${PATH:+$PATH:}/usr/bin"
export PATH="${PATH:+$PATH:}/bin"
export PATH="${PATH:+$PATH:}/usr/sbin"
export PATH="${PATH:+$PATH:}/sbin"

echo() {
    if [[ -t 1 ]]; then
        builtin echo $'\033[0;37m'"$@"$'\033[0m'
    else
        builtin echo "$@"
    fi
}

exec() {
    if [[ "$(command -v "$1")" -ef "$shim_realpath" ]]; then
        path_remove "$shims_dir"
    fi
    if [[ -n "$SHIMS_DEBUG" ]]; then
        echo "$@" >&2
    fi
    builtin exec "$@"
}

load_local_profiles() {
    unset -f load_local_profiles
    local local_profile
    if [[ -d "$shims_dir/common/local" ]]; then
        for local_profile in "$(ls "$shims_dir/common/local")"; do
            if [[ -n "$local_profile" ]]; then
                source "$shims_dir/common/local/$local_profile"
            fi
        done
    fi
}
load_local_profiles
