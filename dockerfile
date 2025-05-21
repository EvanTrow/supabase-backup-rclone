FROM ubuntu:25.10

# Install system utilities: curl, unzip, cron, rclone, tar, git, build-essential, tzdata
RUN apt-get update && \
    apt-get install -y curl unzip gnupg ca-certificates cron tar git build-essential gettext tzdata && \
    curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    cp rclone-*-linux-amd64/rclone /usr/bin/rclone && \
    chmod +x /usr/bin/rclone && \
    chmod 755 /usr/bin/rclone && \
    rm -rf rclone-*

# Set default timezone to America/New_York, allow override with TZ env
ENV TZ=America/New_York

# Configure timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install Homebrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# Install Supabase CLI
RUN brew install supabase/tap/supabase

# Create app directory
WORKDIR /app

# Copy backup script and crontab template
COPY backup.sh /usr/local/bin/backup.sh
COPY crontab.template /etc/cron.d/db-backup-cron.template

# Set permissions
RUN chmod +x /usr/local/bin/backup.sh && \
    chmod 0644 /etc/cron.d/db-backup-cron.template && \
    touch /var/log/cron.log

# Set default cron schedule to daily if not provided
ENV CRON_SCHEDULE="0 2 * * *"

# This is where rclone will look for its config file
VOLUME ["/root/.config/rclone/"]

# Generate the actual crontab from template at container start, then start cron
CMD ["/bin/bash", "-c", "ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && envsubst < /etc/cron.d/db-backup-cron.template > /etc/cron.d/db-backup-cron && chmod 0644 /etc/cron.d/db-backup-cron && crontab /etc/cron.d/db-backup-cron && cron -f"]

