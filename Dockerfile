FROM nginx:alpine

# Copy the OSTree repo as static files
COPY repo/ /usr/share/nginx/html/repo/
COPY gpg/pub.gpg /usr/share/nginx/html/repo/key.gpg

# Nginx config for proper MIME types and CORS
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
