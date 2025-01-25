# syntax=docker/dockerfile:1

# example docker run:
# docker run --env=TZ="Europe/Berlin" --env=ADMIN_PASSWORD="admin" -p 631:631 -d ghcr.io/as19git67/cups-airprint:latest

# base image
ARG ARCH=i386
FROM $ARCH/debian:bookworm-slim

# args
ARG VCS_REF
ARG BUILD_DATE

ARG ARG_TZ="Europe/Berlin"
ENV TZ=${ARG_TZ}

# environment
ENV ADMIN_PASSWORD=admin


# install packages
RUN apt-get update \
  && apt-get install -y \
locales \
cups \
cups-pdf \
cups-client \
cups-filters \
avahi-daemon \
avahi-discover \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# add print user
RUN adduser --home /home/admin --shell /bin/bash --gecos "admin" --disabled-password admin \
  && adduser admin sudo \
  && adduser admin lp \
  && adduser admin lpadmin


# disable sudo password checking
RUN echo 'admin ALL=(ALL:ALL) ALL' >> /etc/sudoers

# enable access to CUPS
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid) \
  && echo "ServerAlias *" >> /etc/cups/cupsd.conf

# copy /etc/cups for skeleton usage
RUN cp -rp /etc/cups /etc/cups-skel
ADD cups.config.installed/* /etc/cups-skel

ADD *.deb /home/admin
RUN ln -s /etc/init.d/cups /etc/init.d/lpd
RUN dpkg -i /home/admin/dcp8025dlpr-1.1.2-1.i386.deb
RUN dpkg -i /home/admin/cupswrapperDCP8025D-1.0.2-1.i386.deb
RUN rm /etc/init.d/lpd


# entrypoint
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 755 /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT [ "docker-entrypoint.sh" ]

#RUN lpadmin -p Brother -D "Laserdrucker schwarz-weiß (auto on)"  -L Waschkeller -E -v socket://dcp8025d -m brdcp8022250_cups.ppd -o printer-is-shared=true


# default command
CMD ["cupsd", "-f"]

# volumes
VOLUME ["/etc/cups"]

# ports
EXPOSE 631
