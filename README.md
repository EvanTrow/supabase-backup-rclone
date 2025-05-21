# Supabase Backup with Rclone (Dockerized)

This project provides a Dockerized solution for automated backups of a Supabase PostgreSQL database. It uses the [Supabase CLI](https://supabase.com/docs/guides/cli), [rclone](https://rclone.org/), and cron to dump your database and upload the backups to a remote storage provider (e.g., S3, Google Drive, etc.).

## Features

-   **Automated Backups:** Scheduled via cron (configurable).
-   **Database Dumps:** Dumps roles, schema, and data separately for flexibility.
-   **Compression:** Archives dumps into a single `.tar.gz` file.
-   **Remote Storage:** Uses rclone to upload backups to any supported cloud provider.
-   **Easy Configuration:** All settings via environment variables.

## Prerequisites

-   Docker installed on your system.
-   A configured rclone remote (see [rclone config docs](https://rclone.org/docs/)).
-   Supabase database connection string.

## Quick Start

1. **Clone this repository:**

    ```sh
    git clone https://github.com/yourusername/supabase-backup-rclone.git
    cd supabase-backup-rclone
    ```

2. **Configure rclone:**

    - Create your rclone config file on your host (usually at `~/.config/rclone/rclone.conf`).
    - Test your remote with `rclone lsd <remote>:`

3. **Build the Docker image:**

    ```sh
    docker build -t supabase-backup-rclone .
    ```

4. **Run the container:**

    ```sh
    docker run -d \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /path/to/your/rclone/config:/root/.config/rclone:ro \
      -e TZ="America/New_York" \
      -e CRON_SCHEDULE="0 2 * * *" \
      -e SUPABASE_DB_URI="postgres://user:password@host:port/dbname" \
      -e RCLONE_REMOTE="remote:/supabase_backups" \
      --name supabase-backup \
      supabase-backup-rclone
    ```

    - The `-v /var/run/docker.sock:/var/run/docker.sock` mount is included because supebase-cli required it to interact with the Docker daemon.
    - Replace `/path/to/your/rclone/config` with the path to your rclone config directory.

## Environment Variables

-   `TZ` (optional): Timezone for the container (default: `America/New_York`). Set this to control the timezone used by cron and backup timestamps (e.g., `Europe/London`, `UTC`, etc.)
-   `CRON_SCHEDULE` (optional): Cron schedule for backups (default: `0 2 * * *` - daily at 2:00 AM)
-   `SUPABASE_DB_URI` (required): PostgreSQL connection string.
-   `RCLONE_REMOTE` (required): rclone remote destination (e.g., `remote:/supabase_backups`)
-   `DELETE_OLDER_THAN_X` (optional): Delete backups older than set time period. Default is seconds but other suffixes are avialble: ms|s|m|h|d|w|M|y

## File Structure

-   `backup.sh`: Main backup script.
-   `crontab.template`: Template for cron job.

## How It Works

1. **On container start:**

    - The cron schedule is generated from the template using environment variables.
    - The cron daemon starts and runs the backup script on schedule.

2. **On each backup:**
    - Dumps roles, schema, and data from the Supabase database.
    - Archives the dumps.
    - Uploads the archive to the specified rclone remote.
    - Cleans up temporary files.

---

**Contributions welcome!**
