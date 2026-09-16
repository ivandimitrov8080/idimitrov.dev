---
title: OverTheWire natas notes
date: 2026-09-16
author: Ivan Dimitrov
description: Notes on how I solved OTW natas challenges
---

### Software:

- `mitmproxy --mode socks5 -p 9050`
- `chromium --proxy-server="socks5://localhost:9050"`

---
<style>
ol {
    list-style: none;
    counter-reset: num -1;
}
ol li {
    counter-increment: num;
}
ol li::before {
    content: counter(num) ". ";
    color: red;
}
</style>

0. Visit the page and check the proxy response. The password is hidden in a comment inside the returned html.
`natas1:scfWG6qNEIdzqVyfRwEGXyNUfFZkZeQ7`
1. Same as before but this time you can't rightclick but since we use the proxy it doesn't make a difference.
`natas2:vsDOxoXyq3wckCP1ZmTZ71ngIA606odB`
2. The html contains an img with src="files/pixel.png". Visiting the /files dir in the browser reveals users.txt
hiding the password.
`natas3:K30JrSRHzjxq3paUQuwozY4MNvmNFyhI`
3. The html comment reads **No more information leaks!! Not even Google will find it this time...**
so we check /robots.txt, which disallows /s3cr3t/. Visiting that dir reveals users.txt hiding the password.
`natas4:JDrPnuZAKyl6MkiqQGFIddrqpvgOASth`
4. The page gives a hint that it is only accessible from natas5 virtual host. Clicking on the **Refresh page** link sets
the Referer header which changes the page to say that we are on natas4 virtual host.
We can use mitmproxy to set the Referer header to what is expected. Resending the modified request gives the password.
`natas5:e4z2Noy3oqwPJUWzJH0dseN67Cn1sy2M`
5. The page says **Access disallowed. You are not logged in**. The proxy shows a cookie set for the request **loggedin=0**.
Changing that to **loggedin=1** and replaying the request reveals the password.
`natas6:7mhjtShJAcld2NYbKHEadnhEwRn2P8VT`
6. The page has a form to input a secret a btn **View sourcecode** that shows a php page that uses **includes/secret.inc**
to check if the submitted value equals the secret in that file. Visiting that path in the browser gives us the value and
after submitting we get the password.
`natas7:B1szg95UcTnrzwnF3i3TzYHlyYh8iBV0`
7. The page has 2 btns for **Home** and **About**. When clicking one it gets the page by using a request param **page=<>**.
The response for each one has a **hint: password for webuser natas8 is in /etc/natas_webpass/natas8**. Using that value
as the request param gives us the password.
`natas8:ugXL95KQmUAJJj6bMezOlBNDyI9Imwkc`
8. The page has **View sourcecode** again like challenge 6 and it shows a page that expects a secret that when encoded equals
a variable visible in the source. Reversing the order of encoding of the value of the variable gives us what the page expects:
**'3d3d516343746d4d6d6c315669563362' | xxd -p -r | rev | base64 -d**.
`natas9:UdxmI27dTaXmnd1rxKQTfws6jihTdcQ9`
