# flightaware-container

## Overview
A Docker container that packages the FlightAware PiAware feeder client for contributing ADS-B aircraft tracking data to the FlightAware network.

## Purpose
Enables easy deployment of the PiAware feeder in containerized environments:
- Contributes ADS-B data to FlightAware network (flightaware.com)
- Provides containerized alternative to native package installation
- Supports remote dump1090 sources via socat relay
- Simplifies setup on non-Raspberry Pi systems

## Architecture

### Dockerfile Structure
Single-stage Debian-based build:
1. **Base**: `debian:bullseye-slim` (latest supported by FlightAware packages)
2. **Dependencies**: Installs `gnupg2`, `lsb-release`, `dirmngr`, `wget`, `socat`
3. **Repository configuration**:
   - Downloads FlightAware apt repository package
   - Installs FlightAware repository configuration
4. **Package installation**: Installs `piaware` package
5. **Configuration**: Copies `feeder_id` cache and startup script
6. **Runtime**: Executes `/usr/bin/startup.sh`

### Key Components

#### startup.sh
Startup script that works around a PiAware limitation:
- **Problem**: PiAware only checks for data on `localhost:30005`, even if configured otherwise
- **Solution**: Uses `socat` to proxy remote dump1090 to localhost when `RECEIVER_HOST` is set
- **Execution**: Runs piaware with `-plainlog` and `-statusfile /status.json` flags

#### piaware.conf
Basic PiAware configuration:
- Enables automatic and manual updates
- Configures receiver as relay type (not direct SDR)
- Sets receiver host to localhost (actual remote host handled by socat)

### PiAware Relay Workaround
PiAware has a bug (as of 2023-08-17) where it uses netcat to verify something is listening on `localhost:30005`, regardless of the configured `receiver-host`. If this check fails, you see:
```
no ADS-B data program is serving on port 30005, not starting multilateration client yet
```

The startup script fixes this by:
1. Checking if `RECEIVER_HOST` environment variable is set and not localhost
2. Starting a background socat process: `socat TCP-LISTEN:30005,fork,reuseaddr "TCP:${RECEIVER_HOST}:30005"`
3. This makes the remote dump1090 appear to be on localhost

## FlightAware PiAware Details

### What PiAware Does
- Connects to dump1090 BEAST protocol output (port 30005)
- Uploads ADS-B aircraft tracking data to FlightAware
- Participates in FlightAware's MLAT (multilateration) network
- Provides status information via JSON file

### Outputs
- **Status file**: `/status.json` (piaware status information)
- **Logs**: Plain text logs to stdout
- **Network**: Uploads data to FlightAware servers
- **MLAT**: Participates in multilateration for enhanced tracking

### Typical Data Flow
```
dump1090/receiver → BEAST (port 30005) → socat relay → piaware → FlightAware network
                                                          ↓
                                                   /status.json
```

## Docker Build
Built using GitHub Actions workflow that creates multi-architecture images:
- Platforms: `linux/amd64`, `linux/arm64`
- Published to: `ghcr.io/paulcager/flightaware-container`
- Triggers: Push to main/master, PRs, manual workflow dispatch

### Build Considerations
- Uses Debian Bullseye for compatibility with FlightAware packages
- Includes socat for remote receiver support
- Relatively large image size due to Debian base and dependencies
- FlightAware packages are maintained by FlightAware, not open source

## Deployment

### Prerequisites
1. FlightAware account and feeder registration
2. Access to ADS-B data source (dump1090, dump1090-proxy, etc.)
3. Feeder ID from FlightAware (stored in `/var/cache/piaware/feeder_id`)

### Typical Usage
```bash
docker run -d \
  -e RECEIVER_HOST=dump1090-proxy \
  -v /path/to/feeder_id:/var/cache/piaware/feeder_id:ro \
  ghcr.io/paulcager/flightaware-container:latest
```

### Environment Variables
- `RECEIVER_HOST`: Hostname/IP of dump1090 source (default: localhost)
  - If set to anything other than "localhost", socat relay is started automatically

### Volume Mounts
- `/var/cache/piaware/feeder_id`: Persistent feeder ID (optional but recommended)
- Custom `/etc/piaware.conf`: Override default configuration (optional)

### Network Requirements
- **Outbound**: Connection to FlightAware servers (HTTPS, various ports)
- **Data source**: Connection to dump1090 on port 30005 (BEAST protocol)
- **No inbound ports required** (unlike some other feeders)

## Configuration

### Initial Setup
1. Sign up at flightaware.com and claim your feeder
2. Feeder will auto-register on first run if no `feeder_id` exists
3. Check FlightAware stats page to verify data is being received
4. Configure MLAT settings via FlightAware website

### PiAware Configuration Options
PiAware supports many configuration options via environment variables or config file:
- `receiver-host`: Data source host (handled by socat in this container)
- `receiver-port`: Data source port (default: 30005)
- `receiver-type`: Type of receiver (set to "relay" for dump1090 data)
- `allow-auto-updates`: Allow PiAware software updates
- `allow-manual-updates`: Allow manual update triggers

See FlightAware documentation for full configuration reference.

## Integration with Other Services

### Works With
- **dump1090**: Primary ADS-B decoder
- **dump1090-proxy**: For aggregating multiple receivers
- **FR24Feed**: Can run alongside for Flightradar24
- **RadarBox**: Can run alongside for RadarBox24

### Monitoring
- Status information available in `/status.json`
- Plain text logs to stdout (use `docker logs`)
- FlightAware website provides detailed statistics and coverage maps
- MLAT participation visible on FlightAware stats page

## Limitations
- Requires Debian Bullseye (latest supported by FlightAware)
- PiAware relay bug requires socat workaround
- Larger image size compared to pure Go applications
- Proprietary client (not open source)
- Auto-updates may require container restart

## Development Notes
- The socat workaround in `startup.sh` is critical for remote dump1090 support
- FlightAware repository: `https://flightaware.com/adsb/piaware/files/packages/`
- The `feeder_id` file is created automatically but persisting it prevents re-registration
- PiAware uses `-plainlog` for container-friendly logging (no syslog)
- Status file at `/status.json` can be volume mounted for monitoring

## Differences from FR24 and RadarBox Feeders
- **Auto-discovery**: PiAware auto-registers and claims via website
- **MLAT**: FlightAware has extensive MLAT network
- **Privacy**: FlightAware is open access (data freely available)
- **No web interface**: Unlike FR24, no built-in stats web server
- **Relay support**: Requires socat workaround (others work more naturally)
