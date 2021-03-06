#!/usr/bin/env bash
set -e

check_group() {
  target_gid=$(stat -c "%g" "$1")
  if [ "$(grep "$target_gid" -c /etc/group)" -eq "0" ]; then
    groupadd -g "$target_gid" localworker
    usermod -g localworker worker
  else
    group=$(getent group "$target_gid" | cut -d: -f1)
    usermod -g "$group" worker
  fi

  target_uid=$(stat -c "%u" "$1")
  if [ "$(grep "$target_uid" -c /etc/passwd)" -eq "0" ]; then
    usermod -u "$target_uid" worker
  fi
}

# environment specific configuration
case $RAILS_ENV in
  development )
    set -x
    check_group .
    bundle config --global frozen 0
    bundle check || bundle install
    ;;
  test )
    set -x
    check_group .
    bundle config --global frozen 0
    bundle check || bundle install
    rake db:create db:schema:load --trace
    ;;
  staging|production )
    ;;
  * )
    printf 'Unknown RAILS_ENV value: %s\n' "${RAILS_ENV:-empty}"
    ;;
esac

# application specific configuration
case $1 in
  puma|rails )
    gosu worker rake db:migrate --trace
    gosu worker rake assets:precompile --trace
    ;;
  bundle )
    exec "$@"
    ;;
esac

exec gosu worker "$@"
