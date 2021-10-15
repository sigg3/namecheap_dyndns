# What is it?
Simple cronjob for updating your namecheap Dynamic A+ DNS record when your WAN ip changes. It works by having curl send a specially crafted HTTPS request, c.f. Namecheap support page <a href="https://www.namecheap.com/support/knowledgebase/article.aspx/29/11/how-to-dynamically-update-the-hosts-ip-with-an-http-request/">how-to-dynamically-update-the-hosts-ip-with-an-http-request/</a>.

Run the script without arguments for usage info.
<pre>
dyndns.sh <subdomain> <domain> <password | FILE> [verbose]

How to update:
  * TLD:       dyndns.sh @ domain.ext mydyndnspassword
  * subdomain  dyndns.sh subdomain domain.ext mydyndnspassword
  * wildcard   dyndns.sh * domain.ext ~/.conf/ncheap_dns_pass

Password field required. It can be either a string or full path
to a file containing the password (safer). Note: This is not your
Namecheap user account password, but the Dynamic DNS password.

dyndns.sh will only request DNS record change if WAN ip has changed.
Use -v flag or a 1 as the last arg to run verbosely.
</pre>


# One-off
Using the imaginary password "71b559581bdde8dbb4f8756575321ea3", the command:
<pre>./dyndns.sh @ github.com 71b559581bdde8dbb4f8756575321ea3</pre>
will update the github.com DNS A+ records to point to the WAN ip of the machine running the command.

<pre>./dyndhs.sh wiki github.com 71b559581bdde8dbb4f8756575321ea3</pre>
will update the wiki.github.com subdomain A+ DNS record to point to the WAN ip of the machine running the command.


# Automation using cron

The script is intended to be run as a cronjob every 10-15 minutes. To avoid putting your password in plaintext in crontab, simply create a file in e.g. /root/.namecheap_dyndns and pass the full path as the password parameter.

<pre>$ sudo echo "71b559581bdde8dbb4f8756575321ea3" > /root/.namecheap_dyndns
$ sudo crontab -e</pre>

Then add the following to crontab:
<pre>
*/15 * * * *  /bin/bash /home/sigg3/namecheap_dyndns/dyndns.sh www domain.com /root/.namecheap_dyndns
</pre>

If you're running cron as a regular user, make sure to set the right permissions on the file so it's not accessible by all.
