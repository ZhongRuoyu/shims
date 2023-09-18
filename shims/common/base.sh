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

echo() {
  if [[ -t 1 ]]; then
    builtin echo $'\033[0;37m'"$*"$'\033[0m'
  else
    builtin echo "$@"
  fi
}

which() {
  local exe
  exe="$(command -v "$1")"
  if [[ -n "$exe" ]] && [[ "$exe" -ef "$shim_realpath" ]]; then
    local saved_path="$PATH"
    path_remove "$shims_dir"
    exe="$(command -v "$1")"
    export PATH="$saved_path"
  fi
  builtin echo "$exe"
}

exec() {
  local exe
  exe="$(which "$1")"
  if [[ -z "$exe" ]]; then
    echo "command not found: $1" >&2
    exit 1
  fi
  shift
  if [[ -n "$SHIMS_DEBUG" ]]; then
    echo "$exe" "$@" >&2
  fi
  builtin exec "$exe" "$@"
}

load_local_profiles() {
  unset -f load_local_profiles
  local saved_nullglob
  saved_nullglob="$(shopt -p nullglob)"
  shopt -s nullglob
  local local_profile
  if [[ -d "$SHIMS_LOCAL_PROFILES_PATH" ]]; then
    for local_profile in "$SHIMS_LOCAL_PROFILES_PATH"/*; do
      # shellcheck source=/dev/null
      source "$local_profile"
    done
  fi
  if [[ -d "$shims_dir/common/local" ]]; then
    for local_profile in "$shims_dir/common/local"/*; do
      # shellcheck source=/dev/null
      source "$local_profile"
    done
  fi
  eval "$saved_nullglob"
}
load_local_profiles
