# To use: source wwd.sh in your shell, then run: wwd

wwd() {
  local pull_flag=""
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

  systemctl --user start podman.socket

  podman run --rm -it ${pull_flag} \
    -v /var/run/user/$(id -u)/podman/podman.sock:/var/run/user/1000/podman/podman.sock \
    -v "$PWD":/workspace \
    -w /workspace \
    -v /dev/bus/usb:/dev/bus/usb \
    --cap-add=NET_RAW \
    --network=host \
    --tmpfs /tmp \
    --userns=keep-id:uid=$(id -u),gid=$(id -g) \
    ghcr.io/whatwedo/iac-shell:latest bash --login
}
