# Use the same base image
FROM akashisn/ffmpeg:7.0.2

# Install needed tools: curl, jq, sudo, and inotify-tools for file monitoring
RUN apt-get update && apt-get install -y curl jq sudo inotify-tools && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Bundle runtime scripts so GHCR pull mode runs without host bind-mounts.
COPY app/ /app/

# Bundle test scripts for optional in-container validation commands.
COPY tests/ /tests/

RUN chmod +x /app/entrypoint.sh /tests/*.sh
