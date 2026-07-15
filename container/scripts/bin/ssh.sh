go() {
  if [ $# -eq 0 ]; then
    echo "Usage: go [ssh-options] user@host"
    return 1
  fi

  # Pass all arguments to ssh, allocate a tty (-t) and run sudo su - on the remote side
  ssh -t "$@" 'sudo su -'
}
