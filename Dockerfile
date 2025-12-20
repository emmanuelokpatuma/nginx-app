FROM nginx:alpine

WORKDIR /app

# If you don't have a custom nginx.conf, comment out or remove the line below
# COPY nginx.conf /etc/nginx/nginx.conf

# Copy the static files into the container
COPY . /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]



