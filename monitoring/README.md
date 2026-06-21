# Production Monitoring

This directory contains simple Bash-based monitoring for the production Docker Compose stack.

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
