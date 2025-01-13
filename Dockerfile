# Use an official GitHub Actions runner image
FROM ghcr.io/actions/virtual-environments/ubuntu-20.04:latest

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y git curl && \
    rm -rf /var/lib/apt/lists/*

# Copy the shell script into the container
COPY sync.sh /usr/local/bin/sync.sh

# Make the script executable
RUN chmod +x /usr/local/bin/sync.sh

# Set the entrypoint for the container
ENTRYPOINT ["bash", "/usr/local/bin/sync.sh"]
