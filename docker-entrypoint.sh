#!/bin/bash -e

echo -e "${ADMIN_PASSWORD}\n${ADMIN_PASSWORD}" | passwd admin

if [ ! -f /etc/cups/cupsd.conf ]; then
  cp -rpn /etc/cups-skel/* /etc/cups/
fi

# ensure avahi is running in background (but not as daemon as this implies syslog)
(
while (true); do
  /usr/sbin/avahi-daemon -c || { /usr/sbin/avahi-daemon & }
  sleep 5
done
) &
sleep 1

exec "$@"
