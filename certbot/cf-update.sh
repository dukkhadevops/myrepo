#!/bin/bash

#see api url below to see how these are used
ZONE_ID=1bee9bffffffffffffffffffffffffffff # zone id for contoso.com
RECORD_ID=3b71eeeeeeeeeeeeeeeeeeeeeeeeeeee # record id for _acme-challenge.contoso.com

echo "Update Cloudflare DNS TXT record"

curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type:application/json" \
  --data "{\"type\":\"TXT\",\"name\":\"_acme-challenge.$CERTBOT_DOMAIN\",\"content\":\"$CERTBOT_VALIDATION\",\"ttl\":1}"

echo "Sleep to make sure the DNS change has time to propagate"
sleep 20