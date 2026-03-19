FROM httpd:2.4

# Copy html and css files to the apache htdocs root
COPY ./index.html /usr/local/apache2/htdocs/
COPY ./style.css /usr/local/apache2/htdocs/

# Copy the usage images directory so they can be securely routed in the static build
COPY ./usage /usr/local/apache2/htdocs/usage
USER 1001
EXPOSE 80
