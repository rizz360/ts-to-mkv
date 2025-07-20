# Use the same base image
FROM akashisn/ffmpeg:7.0.2

# Install needed tools: curl, jq, sudo
RUN apt-get update && apt-get install -y curl jq sudo && rm -rf /var/lib/apt/lists/*
