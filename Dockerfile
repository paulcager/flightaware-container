# PiAware feeder for FlightAware
# Using community repository as FlightAware's official APT repo is empty (no packages published)
FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y gnupg2 wget socat ca-certificates

RUN wget https://www.flightaware.com/adsb/piaware/files/packages/pool/piaware/f/flightaware-apt-repository/flightaware-apt-repository_1.2_all.deb && \
    dpkg -i flightaware-apt-repository_1.2_all.deb && \
    rm flightaware-apt-repository_1.2_all.deb

RUN apt-get update && \
    apt-get install -y piaware

COPY startup.sh /usr/bin/


CMD ["/usr/bin/startup.sh"]
