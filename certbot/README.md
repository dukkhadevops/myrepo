# Introduction 

In production (ONLY in production), the Front Door custom endpoint for `contoso.com` (not `www.contoso.com`) is protected by a custom TLS certificate from Let's Encrypt. This is because Front Door does not support managed certificates for the root/apex domain.

We use [certbot](https://certbot.eff.org) to generate the certificate - using the DNS challenge which we automate with Cloudflare API and the certbot auth-hook scripts.

After we generate the cert, we have to convert it to .pfx (for whatever reason, key vault or frontdoor does not like .pem, even though documentation gives the impression that it would work) and upload it to key vault. Front Door will use the latest certificate in key vault.

# Read this!

- Don't go trigger happy and run this pipeline a bunch of times. Let's Encrypt throttles/rate limits us to **5 certificates per domain within 168 hours (1 week)**.

# Pipeline Tasks

## 1. Generate certificate (`renew == false`)
* Use certbot to request for a new certificate
* Use hook scripts to call Cloudflare API to update DNS TXT record to satisfy DNS challenge
* Generates certificate in pem format in the `./live/contoso.com/` folder

## 2. Retrieve old cert and config from key vault (`renew == true`)
* Get certificate and certbot config file from key vault
* Create symlinks becuase that's what certbot expects

## 3. Renew certificate (`renew == true`)
* Use certbot to renew certificate

## 4. Save cert and config to key vault
* Save certs and config to key vault (cl-kv-infra-prod-001)

## 5. Convert .pem to .pfx
* Convert .pem to .pfx becuase that is what Front Door expects

## 6. Upload .pfx to Key Vault
* Upload .pfx to key vault

## 7. Display old and new cert expiration dates
* Display the current cert expiration date and the new cert's expiration (purely for informational purposes)
* Shell command to retrieve cert expiration date:
```
echo | openssl s_client -connect contoso.com:443 2>/dev/null | openssl x509 -noout -dates
```

# Pipeline Parameters
## `dry_run`
* `dry_run` is `false` by default
* Runs certbot commands in dry run mode - meaning no new cert is created or renewed
* Note: the pipeline will still retrieve the previous certificate and re-upload the same certificate to key vault. This is fine as long as the re-uploaded cert is still valid.

## `renew`
* `renew` is `false` by default
* Renewing the existing certificate is better as it does not count against the rate limit for Let's Encrypt. However, it does require all the certs and private keys and configs be in the correct location and named correctly and symlinked correctly
* If `renew` is `false`, the pipeline will ask Let's Encrypt for a new certificate, and there is a rate limit of 5 certificates per domain within 168 hours (1 week).

# Build Notification
Notification has been enabled for this pipeline so that if the pipeline fails, it will notify contoso-infrastructure team  members.
![image](https://dev.azure.com/contoso/6faa90e5-c680-4515-90b2-eeeeeeeeeee/_apis/wit/attachments/28828c29-3707-47dc-89e1-eeeeeeeeeeee?fileName=image.png)
![image1](https://dev.azure.com/contoso/6faa90e5-c680-4515-90b2-eeeeeeeeee/_apis/wit/attachments/5053d0ad-c807-4bd9-a4a5-eeeeeeeeeeee?fileName=image.png)

# Incident response

See this [wiki](https://dev.azure.com/contoso/contoso-infrastructure/_wiki/wikis/contoso-infrastructure.wiki/416/SSL-Certificate-Renewal-Automation-(contoso-certbot)) for incident triage information

# References
* https://certbot.eff.org/docs/using.html
* https://chariotsolutions.com/blog/post/automating-lets-encrypt-certificate-renewal-using-dns-challenge-type/
* https://api.cloudflare.com/#dns-records-for-a-zone-update-dns-record
