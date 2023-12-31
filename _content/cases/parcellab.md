---
title: Parcel Lab integration into international eCommerce app
goal: Integrate the Parcel Lab Post-purchase solution into all US and European WOSG websites
role: Plan, design and implement the integration
date: 2022 - 2023
z: 2
draft: false
---

> parcelLab is the only truly global enterprise post-purchase software provider, enabling brands to increase top-line revenue, decrease operational costs, and optimize the customer
> experience.

[Parcel Lab](https://parcellab.com/)

Parcel lab takes care of the post-purchase operations like order tracking, email notifications, delivery status updates, data processing and more so that businesses don't have to.

---

### Technical overview

This integration is straightforward thanks to the [amazing documentation](https://how.parcellab.works/docs/) provided by the Parcel Lab team.

You really want to use the API even though there's more options to submit data to their platform.

The data model is based on the [tracking](https://how.parcellab.works/docs/onboarding/data-model) - a data object having four fields for the delivery information. An order is
composed of one or more trackings.

Once data is submitted, the platform starts an automated process where it groups the new trackings to their respective orders and starts listening for events like "dispatch",
"payment received" etc. to run custom actions. Each business can configure these events and actions so that they best match their operations. For example an "order created" event
could notify the customer that the order has started as well as deal with some other business logic in the background.

Their [order status page](https://how.parcellab.works/docs/track-and-communicate/order-status-page) is a convenient script that you can configure for your website. The script reads
the URL to find an order number so that it can fetch the most up-to-date information for that order and display it in an iFrame.

This system allows for a seamless, declarative event-based integration where the business takes care of the data and events (and sales) and parcelLab takes care of the rest.

---

### ParcelLab API details

Create the first order when a customer places it.

```hurl
POST https://api.parcellab.com/order/                       # This is the method and the endpoint
user: business-uid                                          # Header
token: access-token                                         # Header
Content-Type: application/json                              # Header
{                                                           # Body starts here
  "xid": "id-of-delivery-before-tracking-number",
  "destination_country_iso3": "DEU",
  "client": "your-client-id",
  "orderNo": "order1",                                      # This is the order ID
  "recipient": "Max Mustermann, parcelLab GmbH",
  "recipient_notification": "Max",
  "email": "max-mustermann@abc.xyz",
  "street": "Landwehrstr. 39",
  "zip_code": "80336",
  "city": "München",
  "billing_info": {
    "name": "Max",
    "phone": "1234",
    "street": "Nice St. 69",
    "city": "Nice",
    "zip_code": "69420",
    "country_iso3": "DEU"
  },
  "articles": [
    {
        "articleNo": "sku",                                 # required
        "articleName": "Some Nice Thingy",                  # required
        "articleCategory": "Nice",                          # optional
        "articleUrl": "https://example.com/nice",           # optional
        "articleImageUrl":"https://example.com/nice.png",   # optional
        "quantity": 69,                                     # optional
    },
  ],
  "customFields": {
    "someField": {
        "anything": "in",
        "here": [],
        "nice": 69
    }
  }
}
```

This will reflect on the parcelLab dashboard.

Add a few trackings to that order once you get the delivery number from the courier.

```hurl
POST https://api.parcellab.com/track/
user: business-uid
token: access-token
Content-Type: application/json
{
  "tracking_number": "1",
  "courier": "dhl-germany",
  "zip_code": "12345",
  "deliveryNo": "1",
  "orderNo": "order1"                                       # This references the above order
}

POST https://api.parcellab.com/track/
user: business-uid
token: access-token
Content-Type: application/json
{
  "tracking_number": "2",
  "courier": "dhl-germany",
  "zip_code": "12345",
  "deliveryNo": "2",
  "orderNo": "order1"
}

POST https://api.parcellab.com/track/
user: business-uid
token: access-token
Content-Type: application/json
{
  "tracking_number": "3",
  "courier": "dhl-germany",
  "zip_code": "12345",
  "deliveryNo": "3",
  "orderNo": "order1"
}
```

The order now has 3 trackings. Parcel Lab integrates with many couriers to provide status updates.

Update the order for whatever reason.

```hurl
POST https://api.parcellab.com/order/
user: business-uid
token: access-token
Content-Type: application/json
{
  "orderNo": "order1",
  "customFields": {
    "customerPleased": true
  }
}
```

These updates can act as event notifications allowing for a declarative configuration.

```hurl
POST https://api.parcellab.com/order/
user: business-uid
token: access-token
Content-Type: application/json
{
  "orderNo": "order1",
  "send_date": "now"                                        # Gets notified that the order has been dispatched
}
```

Complete shipment.

```hurl
POST https://api.parcellab.com/order/
user: business-uid
token: access-token
Content-Type: application/json
{
  "orderNo": "order1",
  "complete": true
}
```

---

All this can be viewed on the tracking page embedded anywhere.

```html
<div id="parcellab-track-and-trace">
  <img src="https://cdn.parcellab.com/img/loading-spinner-1.gif" alt="loading" />
</div>

<script>
  function plTrackAndTraceStart() {
    window.parcelLabTrackAndTrace.initialize({
      plUserId: TYPE_YOUR_USER_ID_HERE,
    });
    var linkTag = document.createElement("link");
    linkTag.rel = "stylesheet";
    linkTag.href = "https://cdn.parcellab.com/css/v5/main.min.css";
    document.getElementsByTagName("head")[0].appendChild(linkTag);
  }
</script>
<script async onload="plTrackAndTraceStart()" src="https://cdn.parcellab.com/js/v5/main.min.js"></script>
```

This shows a nice UI that can be [customized](https://how.parcellab.works/docs/track-and-communicate/order-status-page/configuration#additional-options).
