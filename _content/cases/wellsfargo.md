---
title: Wells Fargo Open Banking APIs integration
goal: Integrate the API so that customers can use their Wells Fargo credit card to put down-payments on US orders
role: Plan, design and implement the integration according to the Wells Fargo specifications
date: Feb, 2021 - Aug, 2021
z: 1
draft: false
---

[Wells Fargo](https://www.wellsfargo.com/) is a US based international financial institution operating in 35 countries and serving over 70 million people worldwide.
[Source](https://en.wikipedia.org/wiki/Wells_Fargo)

They provide an [Open Banking API](https://en.wikipedia.org/wiki/Open_banking) for usage with custom-made business credit cards like the
[Watches of Switzerland credit card](https://www.watchesofswitzerland.com/wos-credit-card).

---

### Technical overview

Integrating Open Banking APIs requires many security and legal precautions. There is always a double layer of encryption for all APIs and communications (even emails).

Many of the specifications and examples are proprietary or lost in the
[mountains of documentation provided by the bank](https://developer.wellsfargo.com/guides/user-guides/open-banking-europe-api-integration/obei). For that reason I will not go into
too much detail about the use cases as I'm not sure what I am allowed to talk about.

One use case documented on their website is the API Keys endpoint.

To generate an API key you need your client credentials with a key and a secret in this format `Authorization: Basic base64(consumerKey:consumerSecret)` as well as the scope in the
form `grant_type=client_credentials&scope=accounts`. There are hundreds of scopes to configure. This gives you an `access_token` which is valid for 24 hours, has the scopes
(permissions) you requested and is used for most API communications.
