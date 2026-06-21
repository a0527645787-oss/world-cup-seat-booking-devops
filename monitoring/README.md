# Production Monitoring

This directory contains simple Bash-based monitoring for the production Docker Compose stack.

It includes:

- A cron-based health check and automatic app restart script.
- Prometheus metrics scraping for the Flask app.
- Grafana dashboards and visualization support.

## What It Monitors

The health check script calls the Flask health endpoint through Nginx:

```bash
http://localhost/health
```

Successful checks are quiet and do not write a log line every time. This keeps the log useful and prevents normal healthy traffic from creating a huge file.

## Health Check

`health_check.sh` uses:

```bash
curl -fsS http://localhost/health
```

If a check fails, the script retries 3 times with 5 seconds between attempts. The log file includes timestamps so repeated failures can be matched with deployment or server events.

If `monitoring/health_check.log` grows larger than 1 MB, the script keeps only the last 200 lines.

## Logs, Health Checks, And Metrics

Logs are timestamped text events. In this project, `monitoring/health_check.log` records health check failures, Docker container state, and restart attempts.

Health checks answer a simple question: is the app responding right now? The `/health` endpoint is used by the Bash script to decide whether the app looks healthy.

Metrics are numeric time-series data. The Flask app exposes Prometheus metrics at `/metrics`, including default Python/process metrics from `prometheus-client` and a request counter named `flask_http_requests_total`.

## Cron

Cron runs commands on a schedule. The installer adds one cron entry that runs the health check every 5 minutes.

The installer removes any existing entry for the same script before adding the new one, so running it more than once does not create duplicate cron jobs.

## Automatic Restart

If all retry attempts fail, the script:

- Logs an `ERROR` entry.
- Appends `docker ps` output.
- Appends the last 40 lines from `flask_app_prod`.
- Restarts `flask_app_prod`.
- Logs that the restart was attempted.

The script does not print environment variables or write secrets to the monitoring log.

## Prometheus

Prometheus collects metrics by scraping HTTP endpoints on a schedule.

The production Compose stack runs Prometheus with this config:

```text
monitoring/prometheus/prometheus.yml
```

Prometheus scrapes the Flask app inside the Docker network:

```text
app:5000/metrics
```

For demo and debugging, Prometheus is exposed on:

```text
http://SERVER_IP:9090
```

## Grafana

Grafana visualizes metrics collected by Prometheus.

The production Compose stack runs Grafana on:

```text
http://SERVER_IP:3000
```

The Prometheus data source is provisioned automatically from:

```text
monitoring/grafana/provisioning/datasources/prometheus.yml
```

If provisioning fails, add Prometheus manually in Grafana:

1. Open `http://SERVER_IP:3000`.
2. Go to Connections or Data sources.
3. Add a Prometheus data source.
4. Use this URL:

```text
http://prometheus:9090
```

5. Save and test the data source.

## Run With Docker Compose

From the project root on the production server:

```bash
docker compose -f docker-compose.prod.yml up -d
```

If the Flask image was rebuilt with the new `/metrics` endpoint, recreate the app container too:

```bash
docker compose -f docker-compose.prod.yml up -d --force-recreate app prometheus grafana
```

## Security Warning

Ports `9090` and `3000` are exposed for demo and debugging. In a real production environment, do not leave Prometheus or Grafana open to the whole internet.

Restrict access with security groups, firewall rules, VPN, SSH tunnel, private networking, or an authenticated reverse proxy. Also change Grafana's default admin password before using it beyond a demo.

## Install

Run this from the project root on the production server:

```bash
chmod +x monitoring/install_cron.sh
./monitoring/install_cron.sh
```

## View Logs

```bash
tail -f monitoring/health_check.log
```
