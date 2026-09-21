#!/usr/bin/env bash
set -euo pipefail

# Debian's /etc/profile hardcodes PATH for login shells, clobbering the ENV PATH
# set in the Containerfile (which is why ansible/molecule in the venv aren't
# found). /etc/profile sources /etc/profile.d/*.sh AFTER that reset, so re-add
# the venv and helper bin dirs here to make them win for login shells.
cat > /etc/profile.d/iac-path.sh <<'SH'
export PATH="/opt/iac-shell/bin:/opt/python-venv/bin:$PATH"
SH

# Append PS1 and helper to global bashrc in a way safe for Docker build layering

# Helper to print current git branch if in a git repository
cat >> /etc/bash.bashrc <<'BASH'
__iac_git_branch() {
  # Only attempt if git is available
  command -v git >/dev/null 2>&1 || return
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    printf " \001\e[0;35m\002(%s)\001\e[0m\002" "$branch"
  fi
}
BASH

# PS1: bold white IAC; git branch printed immediately after IAC on same line
cat >> /etc/bash.bashrc <<'BASH'
export PS1='\[\e[1;37m\]IAC\[\e[0m\]$(__iac_git_branch) \[\e[1;34m\]\w\[\e[0m\]\$ '
BASH

cat >> /etc/bash.bashrc <<'BASH'
source /opt/iac-shell/bin/findup.sh
BASH

# Start ssh-agent, unless one is already reachable. `ssh-add -K` loads the
# YubiKey's resident keys into it.
cat >> /etc/bash.bashrc <<'BASH'
[ -S "${SSH_AUTH_SOCK:-}" ] || eval $(ssh-agent -s) > /dev/null
BASH

# Use the 1Password SSH agent by default; iac() mounts its socket. A host can opt
# back out with `IdentityAgent SSH_AUTH_SOCK`. HOME is ephemeral, so this lives in /etc.
mkdir -p /etc/ssh/ssh_config.d
cat > /etc/ssh/ssh_config.d/10-1password.conf <<CONF
Host *
  IdentityAgent ${HOME}/.1password/agent.sock
CONF

# Debian ships this Include, but don't rely on it. It must come first — ssh_config
# keeps the first value it finds for each keyword.
if ! grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/ssh_config\.d/\*\.conf' /etc/ssh/ssh_config; then
  sed -i '1i Include /etc/ssh/ssh_config.d/*.conf' /etc/ssh/ssh_config
fi

# Persist bash history in the mounted history volume (see source.sh). Keep the
# history file out of the ephemeral HOME, and append each command immediately so
# nothing is lost when the --rm container exits.
cat >> /etc/bash.bashrc <<'BASH'
export HISTFILE="$HOME/.history/bash_history"
export HISTSIZE=10000
export HISTFILESIZE=100000
shopt -s histappend
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
BASH
