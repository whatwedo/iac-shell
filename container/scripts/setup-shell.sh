#!/usr/bin/env bash
set -euo pipefail

# Debian's /etc/profile hardcodes PATH for login shells, clobbering the ENV PATH
# set in the Containerfile (which is why ansible/molecule in the venv aren't
# found). /etc/profile sources /etc/profile.d/*.sh AFTER that reset, so re-add
# the venv and helper bin dirs here to make them win for login shells.
cat > /etc/profile.d/wwd-path.sh <<'SH'
export PATH="/opt/iac-shell/bin:/opt/python-venv/bin:$PATH"
SH

# Append PS1 and helper to global bashrc in a way safe for Docker build layering

# Helper to print current git branch if in a git repository
cat >> /etc/bash.bashrc <<'BASH'
__wwd_git_branch() {
  # Only attempt if git is available
  command -v git >/dev/null 2>&1 || return
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    printf " \001\e[0;35m\002(%s)\001\e[0m\002" "$branch"
  fi
}
BASH

# PS1: bold white WWD; git branch printed immediately after WWD on same line
cat >> /etc/bash.bashrc <<'BASH'
export PS1='\[\e[1;37m\]WWD\[\e[0m\]$(__wwd_git_branch) \[\e[1;34m\]\w\[\e[0m\]\$ '
BASH

cat >> /etc/bash.bashrc <<'BASH'
source /opt/iac-shell/bin/findup.sh
source /opt/iac-shell/bin/ssh.sh
BASH

# Start ssh-agent
cat >> /etc/bash.bashrc <<'BASH'
eval $(ssh-agent -s) > /dev/null
BASH

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
