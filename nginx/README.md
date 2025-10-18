# Nginx scripts

**Vibecode warning**
These bash scripts were very much vibecoded. However they have been tested to work and my rudimentary knowledge of bash scripting has validated them. 
**Use at your own risk.**

## nginx_script.sh

`nginx_script.sh` automates the creation of nginx server blocks with the other `create_*` scripts present being called under this main script. It creates blocks according to a `services.csv` file that is formatted like so:

|service|domain|port|target_host|optional_flag|proxy_subpath|
|---|---|---|---|---|---|
|service1|example.com|8080|192.168.0.1|||
|service2|example.com|8081|192.168.0.1|--websockets||
|service3|example.com|8082|192.168.0.1|--websockets|home|
|service4|example.net|8080|192.168.0.2|||


The only `optional_flag` supported at the moment is --websockets which adds to the nginx block.
```
proxy_http_version 1.1;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
```

`proxy_subpath` allows redirecting straight to 192.168.0.1:8082/home/ so you don't end up with service2.example.com/home/ and can use service2.example.com directly instead.

### create_service.sh

`create_service.sh` is the main bash script that creates the server block according to `services.csv`. It assumes **https** so an SSL certificate needs to be present in:
```
ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
```
I have assumed the use of certbot / letsencrypt and an individual ssl certificate for each domain used. This means when creating an SSL certificate you shouldn't be combining multiple domains in one command likeso:
```
sudo certbot -d example.com -d example.net
```
But you'll need to obtain them separately:
```
sudo certbot -d example.com -d example.com
sudo certbot -d example.com -d example.net
```

### create_wildcard.sh

The SSL certificates I am using are wildcard certificates meaning they are valid for [anything].example.com. This can be problematic when unspecified domains such as memes.example.com can be redirected to the first valid block e.g. service1.example.com.

`create_wildcard.sh` creates a wildcard block for each unique domain specified in `services.csv` to catch these unspecified subdomains and returns a 404 response (not found). 

### create_catch_all.sh

I discovered some other weird interactions outside of [anything].example.com being redirected to a valid domain, albeit with certificate warnings. To avoid this occuring `create_catch_all.sh` is called to create a final 'catch all' block to return 444 response (no response).

