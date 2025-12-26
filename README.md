# Nginx-cert
The point of this repo is to hold the nginx configuration for PKI demo use cases where certificate auto-renewal is displayed. The goal is also to get into IaC to make this use case and the ones to come easily reproducible by anyone interested in PKI.

## Script creating the webpage with the certificate information
To maintain a dependance free static HTML page, the certificate should be fetched on service start/restart. Since the service needs to be restarted when the x.509 certificate is changed, this izs not an issue and can be done easily by modifying the service itself.
**Running the script once before modifying the nginx service is the right starting point to test verify permissions etc.**

[The script is very straightforward.](script/update_cert_info.sh)

## Modifying Nginx to actually display this page
Next step is adding a /cert endpoint which will actually display the new page with the certificate info.

## Editing the nginx service
The best way to ensure the new static HTML page is created with the new certificate info is to have the script run as a pre-step.
```bash
sudo EDITOR=vim systemctl edit nginx
```
```bash 
[Service]
ExecStartPre=/home/ubuntu/update_cert_info.sh #to replace with the actual path of the script
ExecReloadPre=/home/ubuntu/update_cert_info.sh #to replace with the actual path of the script
```
This can then be tested out with a restart of the service.

## Customizing the webpage's UI
Asking AI for a basic [CSS](web/style.css) to highlight those elements does the trick. Here's the final result:

<img src="docs/UI_screenshot.png" alt="UI preview" width="900"/>
