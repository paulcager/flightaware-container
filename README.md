# FlightAware PiAware Feeder Container

Docker container for running FlightAware's PiAware feeder to contribute ADS-B aircraft tracking data to the FlightAware network.

## Quick Start

```bash
docker run -d \
  --name piaware \
  -e RECEIVER_HOST=your-dump1090-host \
  ghcr.io/paulcager/flightaware-container:latest
```

## What This Does

- Connects to your ADS-B receiver (dump1090)
- Uploads aircraft tracking data to FlightAware
- Participates in MLAT (multilateration) for enhanced tracking
- Auto-registers as a new feeder on first run

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RECEIVER_HOST` | `localhost` | Hostname or IP of your dump1090 instance |

### Example with Remote Receiver

```bash
docker run -d \
  --name piaware \
  --restart unless-stopped \
  -e RECEIVER_HOST=dump1090-proxy \
  ghcr.io/paulcager/flightaware-container:latest
```

### Persisting Feeder ID

To avoid re-registration on container restart:

```bash
docker run -d \
  --name piaware \
  --restart unless-stopped \
  -e RECEIVER_HOST=dump1090-proxy \
  -v /path/to/feeder_id:/var/cache/piaware/feeder_id \
  ghcr.io/paulcager/flightaware-container:latest
```

## Docker Compose

```yaml
piaware:
  image: ghcr.io/paulcager/flightaware-container:latest
  restart: unless-stopped
  environment:
    RECEIVER_HOST: dump1090-proxy
  volumes:
    - ./piaware_feeder_id:/var/cache/piaware/feeder_id
```

## Setup Steps

1. **Run the container** with your dump1090 host configured
2. **Check logs** for the feeder ID: `docker logs piaware`
3. **Claim your feeder** at https://flightaware.com/adsb/piaware/claim
4. **View your stats** at https://flightaware.com/adsb/stats/user/

## Viewing Logs

```bash
# Follow logs
docker logs -f piaware

# Check for successful connection
docker logs piaware | grep -i "connected to flightaware"
```

## Requirements

- ADS-B receiver running dump1090 (or compatible)
- dump1090 BEAST output on port 30005
- Internet connection for uploading to FlightAware
- FlightAware account (free)

## How It Works

The container includes a workaround for PiAware's localhost-only limitation:
- PiAware expects dump1090 on `localhost:30005`
- When `RECEIVER_HOST` is set, socat creates a relay
- This allows PiAware to work with remote receivers

## Troubleshooting

### No data being sent

Check that dump1090 is accessible:
```bash
# From your Docker host
nc -zv your-dump1090-host 30005
```

### Container exits immediately

Check logs for errors:
```bash
docker logs piaware
```

### Feeder not showing on FlightAware

- Wait 5-10 minutes for data to appear
- Ensure you've claimed your feeder ID
- Check that dump1090 is receiving aircraft data

## Technical Details

- **Base Image**: Debian Bullseye (required by FlightAware packages)
- **PiAware Version**: Latest from FlightAware repository
- **Ports Used**: None (outbound only)
- **Data Protocol**: BEAST format on port 30005

## Advanced Configuration

### Custom Configuration File

To override the default `piaware.conf`:

```bash
docker run -d \
  --name piaware \
  -e RECEIVER_HOST=dump1090-proxy \
  -v /path/to/custom-piaware.conf:/etc/piaware.conf:ro \
  ghcr.io/paulcager/flightaware-container:latest
```

### Status Monitoring

PiAware writes status to `/status.json`:

```bash
docker exec piaware cat /status.json
```

## Links

- FlightAware: https://flightaware.com
- Claim Feeder: https://flightaware.com/adsb/piaware/claim
- PiAware Documentation: https://flightaware.com/adsb/piaware/
- GitHub Repository: https://github.com/paulcager/flightaware-container

## Developer Documentation

For detailed technical documentation, architecture details, and development notes, see [CLAUDE.md](CLAUDE.md).

## License

This container uses FlightAware's proprietary PiAware software. The container configuration and scripts are provided as-is for community use.
