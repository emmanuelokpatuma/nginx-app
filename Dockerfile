# Use the official Nginx image
FROM nginx:alpine

# Copy your Nginx configuration file into the container (if you have one)
COPY nginx.conf /etc/nginx/nginx.conf

# Copy your static website or app files into the container (adjust the path)
COPY . /usr/share/nginx/html

# Expose the port Nginx will be running on
EXPOSE 80

# Start Nginx in the foreground (this is the default CMD in the nginx:alpine image)
CMD ["nginx", "-g", "daemon off;"]

