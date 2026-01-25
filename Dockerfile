FROM nginx:alpine

# Copy the OSTree repo as static files
COPY repo/ /usr/share/nginx/html/repo/

# Copy .flatpakref for easy install
COPY com.lbk.launcher.flatpakref /usr/share/nginx/html/com.lbk.launcher.flatpakref

# Nginx config for proper MIME types and CORS
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
