function commandunit() {
  function __commandunit_user_option() {
    case "$(uname -sr)" in

     Darwin*)
       echo -n ""
       ;;

     Linux*Microsoft*)
       echo -n "-u" "$(id -u):$(id -g)"
       ;;

     Linux*)
       echo -n "-u" "$(id -u):$(id -g)"
       ;;

     CYGWIN*|MINGW*|MSYS*)
       echo -n "-u" "$(id -u):$(id -g)"
       ;;

     # Add here more strings to compare
     # See correspondence table at the bottom of this answer

     *)
       echo -n "-u" "$(id -u):$(id -g)"
       ;;
    esac
  }
  local _project_basedir="${PWD}"
  local _hostfsroot_mountpoint="/var/lib/commandunit"
  local _docker_repo_name="dakusui/commandunit"
  local _image_version="v1.21"
  local _suffix=""
  local _entrypoint=""
  local _loglevel="${COMMANDUNIT_LOGLEVEL:-ERROR}"
  local _image_name _args _show_image_name=false _i _s _quit=false _help=false
  _args=()
  _s=to_func
  for _i in "${@}"; do
    if [[ "${_s}" == to_func ]]; then
      if [[ $_i == "--snapshot" ]]; then
        _image_version="v1.22"
        _suffix="-snapshot"
      elif [[ $_i == "--debug" ]]; then
        _entrypoint="--entrypoint=/bin/bash"
      elif [[ $_i == "--show-image-name" ]]; then
        _show_image_name=true
      elif [[ $_i == "--quit" ]]; then
        _quit=true
      elif [[ $_i == "--help" ]]; then
        _help=true
        _args+=("${_i}")
      elif [[ $_i == "--" ]]; then
        _s=to_container
      else
        _args+=("${_i}")
      fi
    else
      _args+=("${_i}")
    fi
  done
  _image_name="${_docker_repo_name}:${_image_version}${_suffix}"
  if ${_show_image_name}; then
    echo "${_image_name}"
  fi
  if ${_help}; then
    echo "Usage: commandunit [WRAPPER OPTION]... [--] [OPTION]... [SUBCOMMAND]..."
    echo ""
    echo "A wrapper function for 'commandunit' to invoke its docker image.".
    echo "Followings are switching options to control the wrapper's behaviour."
    echo "Options not listed here or ones after the separator (--) are passed to the docker image directly."
    echo ""
    echo "Wrapper options:"
    echo "--snapshot        Use the snapshot image instead of the latest released one. Development purpose only."
    echo "--debug           Get the shell of the docker image. Type Ctrl-D to quit it. Development purpose only."
    echo "--show-image-name Print the image name. Useful to figure out the version."
    echo "--quit            Quit before running the image. With --show-image-name, useful to figure out the image version"
    echo "--help            Show this help and pass the --help option to the docker image."
    echo "--                A separator to let this wrapper know the options after it should be passed directly to the image"
    echo ""
  fi
  ${_quit} && return 0
  # shellcheck disable=SC2086
  # shellcheck disable=SC2046
  docker run \
    $(__commandunit_user_option) \
    --env COMMANDUNIT_PWD="${_project_basedir}" \
    --env COMMANDUNIT_LOGLEVEL="${_loglevel}" \
    -v "${_project_basedir}:${_hostfsroot_mountpoint}${_project_basedir}" \
    ${_entrypoint} \
    -i "${_image_name}" \
    "${_args[@]}"
}

if (return 0 2>/dev/null); then
  export -f commandunit
  echo "This file was sourced. Try 'commandunit --help' to see usage." >&2
else
  commandunit --test-srcdir=./src/test/scripts --test-workdir=./commandunit-out/work --test-reportdir=./commandunit-out/report -- "${@}"
fi
