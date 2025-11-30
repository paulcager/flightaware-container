# PiAware feeder for FlightAware
# Using Bookworm for official FlightAware repository support (PiAware 10.x)
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y gnupg2 wget socat ca-certificates

# Install official FlightAware repository configuration
# PiAware 9.0+ officially supports Bookworm
RUN wget -O /tmp/flightaware-apt-repository.deb \
    https://www.flightaware.com/adsb/piaware/files/packages/pool/piaware/f/flightaware-apt-repository/flightaware-apt-repository_1.2_all.deb && \
    dpkg -i /tmp/flightaware-apt-repository.deb && \
    rm /tmp/flightaware-apt-repository.deb

RUN apt-get update && \
    apt-get install -y piaware

COPY startup.sh /usr/bin/


CMD ["/usr/bin/startup.sh"]
