# Derived from https://apt.rb24.com/inst_rbfeeder.sh

# bullseye is the latest supported by rbfeeder.
FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y gnupg2 lsb-release dirmngr wget socat

RUN wget https://flightaware.com/adsb/piaware/files/packages/pool/piaware/f/flightaware-apt-repository/flightaware-apt-repository_1.1_all.deb && \
    dpkg -i flightaware-apt-repository_1.1_all.deb 

RUN apt-get update && \
    apt-get install -y piaware

COPY feeder_id /var/cache/piaware/
COPY startup.sh /usr/bin/


CMD ["/usr/bin/startup.sh"]
