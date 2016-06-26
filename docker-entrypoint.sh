#!/usr/bin/env bash
set -ex

check_group() {
  target_gid=$(stat -c "%g" "$1")
  if [ "$(grep "$target_gid" -c /etc/group)" -eq "0" ]; then
    groupadd -g "$target_gid" localworker
    usermod -g localworker worker
  else
    group=$(getent group "$target_gid" | cut -d: -f1)
    usermod -g "$group" worker
  fi
}

# environment specific configuration
case $RAILS_ENV in
  development|test )
    check_group .
    bundle config --global frozen 0
    bundle check || bundle install
    ;;
esac

# application specific configuration
case $1 in
  puma|rails )
    rake db:migrate --trace
    rake assets:precompile --trace
    ;;
  bundle )
    exec "$@"
    ;;
esac

exec gosu worker "$@"
