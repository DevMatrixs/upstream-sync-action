# Use an official GitHub Actions base image
FROM ghcr.io/actions/checkout:latest

# Set the working directory
WORKDIR /workspace

# Copy entrypoint.sh script into the container
COPY entrypoint.sh /entrypoint.sh

# Make the script executable
RUN chmod +x /entrypoint.sh

# Set the default entrypoint to the script
ENTRYPOINT ["/entrypoint.sh"]
