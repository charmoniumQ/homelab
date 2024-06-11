#!/usr/bin/env bash

# Bash: env $(./restic_env_vars.sh) restic list snapshots
# Zsh: env $(=./restic_env_vars.sh) restic list snapshots
# Xonsh: env @($(./restic_env_vars.sh).split()) restic list snapshots

env --chdir=secrets agenix -d restic.env.age | tr '\n' ' '
echo -n ' ' RESTIC_PASSWORD=$(env --chdir=secrets agenix -d resticPassword.age)
echo -n ' ' RESTIC_REPOSITORY=b2:charmonium-backups:home-server
