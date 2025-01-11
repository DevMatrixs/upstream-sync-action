FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache \
    bash \
    git

# Add your script files to the container
ADD *.sh /home/root/

# Make the scripts executable
RUN chmod 555 /home/root/*.sh

# Set the working directory
WORKDIR /home/root

# Set entrypoint to your script
ENTRYPOINT ["/home/root/entrypoint.sh"]
