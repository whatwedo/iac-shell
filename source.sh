# Source this file from your clone of the repository, then run: iac
# See the Setup section in README.md.

iac() {
  local pull_flag=""
  # Extra flags for `podman run`, collected here and expanded just before the
  # image name below — last, so they override the defaults set there (podman
  # keeps the last value for single-value options such as -w or --network).
  local podman_args=()

  while [ $# -gt 0 ]; do
    case "$1" in
    --pull | --pull=*)
      pull_flag="--pull=always"
      shift
      ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        podman_args+=("$1")
        shift
      done
      break
      ;;
    *)
      podman_args+=("$1")
      shift
      ;;
    esac
  done

  # 1Password: the SSH agent socket is mounted into the container, and secrets use
  # a service account token read here, under your normal unlock.
  local op_agent_sock="$HOME/.1password/agent.sock"

  if ! command -v op >/dev/null; then
    echo "iac: 1Password CLI not found on the host" >&2
    return 1
  fi
  if ! op whoami >/dev/null 2>&1; then
    echo "iac: 1Password is locked — unlock it (or run 'op signin') and retry" >&2
    return 1
  fi
  if [ ! -S "$op_agent_sock" ]; then
    echo "iac: no SSH agent socket at $op_agent_sock" >&2
    echo "iac: enable 1Password > Settings > Developer > Use the SSH agent" >&2
    return 1
  fi

  # Passed by name below so the token is inherited, never shown in ps.
  export OP_SERVICE_ACCOUNT_TOKEN
  OP_SERVICE_ACCOUNT_TOKEN="$(op read "${IAC_OP_SERVICE_ACCOUNT_REF:-op://Private/iac-shell-sa/credential}")" || {
    echo "iac: could not read the service account token from 1Password" >&2
    return 1
  }

  systemctl --user start podman.socket

  # The container runs with --rm, so its HOME is ephemeral and bash history
  # would be lost on exit. Persist it in a dedicated podman named volume (auto
  # created on first run) that lives only inside container storage, so the
  # container keeps its own history without touching the host's shell history.
  podman run --rm -it ${pull_flag} \
    -v /var/run/user/$(id -u)/podman/podman.sock:/var/run/user/1000/podman/podman.sock \
    -v "$PWD":/workspace \
    -w /workspace \
    -e HOST_WORKSPACE="$PWD" \
    -v /dev/bus/usb:/dev/bus/usb \
    -v "$op_agent_sock":/home/iac-admin/.1password/agent.sock \
    -e OP_SERVICE_ACCOUNT_TOKEN \
    -v iac-shell-history:/home/iac-admin/.history \
    --cap-add=NET_RAW \
    --network=host \
    --tmpfs /tmp \
    --userns=keep-id:uid=$(id -u),gid=$(id -g) \
    "${podman_args[@]}" \
    ghcr.io/whatwedo/iac-shell:latest bash --login
}
