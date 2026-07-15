# whatwedo iac-shell

shell in a container with tools for managing our infrastructure:

- ansible
- molecule (ansible testing)
- prettier, yamllint, ...

## Requirements

- podman

## Setup

tbd

## Usage

`source <(curl -s https://raw.githubusercontent.com/whatwedo/iac-shell/refs/heads/main/source.sh)`

provides the `wwd` command. You might want to add it to your `.bashrc`.

## Tools

### Helper Commands

**go**: does `ssh` and `sudo su -` in one single command, usage: `go my-server`
