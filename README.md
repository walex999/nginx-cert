# Nginx-cert
The point of this repo is to hold the nginx configuration for PKI demo use cases where certificate auto-renewal is displayed.

## Script creating the webpage with the certificate information
To maintain a dependance free static HTML page, we want the certificate info to be fetched on service start/restart. Since the service needs to be restarted when the x.509 certificate is changed, this is not an issue.
Running it once before modifying the nginx service is the right starting point.

[The script is very straightforward.](script/update_cert_info.sh)

## Modifying Nginx to actually display this page
We add a /cert endpoint which will actually display our new page with the certificate info.

## Editing the nginx service
The best way to ensure the new static HTML page is created with the new certificate info is to have the script run as a pre-step.
```bash
sudo EDITOR=vim systemctl edit nginx
```
```bash 
[Service]
ExecStartPre=/home/ubuntu/update_cert_info.sh #to replace with the actual path of the script
ExecReloadPre=/home/ubuntu/update_cert_info.sh
```
This can then be tested out with a restart of the service. 

## Customizing our page
Asking AI for a basic [CSS](css/style.css) to highlight those elements does the trick.
