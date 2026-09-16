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

