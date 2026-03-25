FROM httpd:2.4

# Copy html and css files to the apache htdocs root
COPY ./index.html /usr/local/apache2/htdocs/
COPY ./style.css /usr/local/apache2/htdocs/

# Copy the usage images directory so they can be securely routed in the static build
COPY ./usage /usr/local/apache2/htdocs/usage
# Set permissions so the apache user can write logs/pid, and change Listen port to 8080
RUN sed -i 's/Listen 80/Listen 8080/' /usr/local/apache2/conf/httpd.conf && \
    mkdir -p /usr/local/apache2/logs && \
    chown -R 1001:0 /usr/local/apache2/logs/ && \
    chmod -R g+w /usr/local/apache2/logs/

USER 1001
EXPOSE 8080
