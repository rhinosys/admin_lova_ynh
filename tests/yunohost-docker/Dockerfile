FROM debian:bookworm
ENV container=docker
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y systemd systemd-sysv dbus curl ca-certificates procps iproute2 && apt-get clean
STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
