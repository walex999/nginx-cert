#!/bin/bash

# Paths to your certificate and output HTML file
CERT_PATH="/etc/nginx/ssl/nginxcrt.crt" #to modify with the actual path of the certificate
OUTPUT_HTML="/var/www/html/cert.html" #to modify with the actual path of the html file (but this is pretty standard)

# Extracting certificate info
SUBJECT=$(openssl x509 -in "$CERT_PATH" -noout -subject | sed 's/subject=//' )
ISSUER=$(openssl x509 -in "$CERT_PATH" -noout -issuer | sed 's/issuer=//' )
SERIAL=$(openssl x509 -in "$CERT_PATH" -noout -serial | sed 's/serial=//' )
START=$(openssl x509 -in "$CERT_PATH" -noout -startdate | sed 's/notBefore=//' )
EXPIRY=$(openssl x509 -in "$CERT_PATH" -noout -enddate | sed 's/notAfter=//' )

# Writing this info to the HTML file
cat <<EOF > "$OUTPUT_HTML"
<!DOCTYPE html>
<html>
<head>
    <title>Certificate Info</title>
    <meta charset="UTF-8">
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>SSL Certificate Info</h1>
    <ul>
        <li><strong>Subject:</strong> $SUBJECT</li>
        <li><strong>Issuer:</strong> $ISSUER</li>
        <li><strong>Serial:</strong> $SERIAL</li>
        <li><strong>Issuing Date:</strong> $START</li>
        <li><strong>Expiration Date:</strong> $EXPIRY</li>
    </ul>
</body>
</html>
EOF
