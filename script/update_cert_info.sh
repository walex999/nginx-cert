#!/bin/bash

# Paths to your certificate and output HTML file
CERT_PATH="/home/ubuntu/crt.crt" #to modify with the actual path of the certificate
OUTPUT_HTML="/var/www/html/cert.html" #to modify with the actual path of the html file (but this is pretty standard)

# Extracting certificate info
SUBJECT=$(openssl x509 -in "$CERT_PATH" -noout -subject)
ISSUER=$(openssl x509 -in "$CERT_PATH" -noout -issuer)
SERIAL=$(openssl x509 -in "$CERT_PATH" -noout -serial)
START=$(openssl x509 -in "$CERT_PATH" -noout -startdate)
EXPIRY=$(openssl x509 -in "$CERT_PATH" -noout -enddate)


# Converting to a human-readable expiry date
START_DATE=$(echo "$START" | sed 's/notBefore=//')
EXPIRY_DATE=$(echo "$EXPIRY" | sed 's/notAfter=//')

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
        <li><strong>Issuing Date:</strong> $START_DATE</li>
        <li><strong>Expiration Date:</strong> $EXPIRY_DATE</li>
    </ul>
</body>
</html>
EOF
