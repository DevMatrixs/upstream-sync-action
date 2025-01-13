# Use Alpine as the base image
FROM alpine:latest

# Install necessary dependencies
RUN apk add --no-cache git curl bash

# Copy the shell script into the container
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint for the container
ENTRYPOINT ["bash", "/usr/local/bin/entrypoint.sh"]
