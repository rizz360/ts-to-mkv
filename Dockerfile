# Use the same base image
FROM akashisn/ffmpeg:7.0.2

# Install needed tools: curl, jq, sudo, and inotify-tools for file monitoring
RUN apt-get update && apt-get install -y curl jq sudo inotify-tools && rm -rf /var/lib/apt/lists/*
