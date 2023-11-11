---
title: Multi-tenant knowledge base website based on Google APIs
goal: Create a modern multi-tenant web app that lets users use their Google Drive as a knowledge base
role: Design and implement the web app
date: Jul 29, 2023 - Nov 5, 2023
z: 5
---

This project aims to be a Google Drive frontend. It uses the Google APIs to fetch document data and display that data in a wiki-style web page.


![thumbnail](/thumbnail.png)


It supports Google Docs, Google Sheets, Google Slides, PDFs and regular files.

---

### Technical overview

I chose NextJS as the backbone for this project as it offers the greatest amount of flexibility while still being very powerful both on the client as well as on the server with an active community and thriving ecosystem.

For styles I chose TailwindCSS with DaisyUI for the optimizations and development speed that come out of using them. Tailwind uses purgecss to minimize the final bundle making the page load and feel faster.

The database is PostgreSQL with Prisma ORM running on Vercel's cloud infrastructure.

For authentication I chose NextAuth with JWT as it's the preferred way to handle auth in a NextJS project.


The actual implementation is a lengthy process involving many moving parts and lots of code. I'll go over the three most challenging problems in no particular order.

Interfacing with Google Drive is done to read the content there and almost never used for writing except for setting and removing permissions. To read the content the reader must have appropriate permissions and that's determined by the auth system with a JWT.
For each request we can get the JWT and use it in the google client to auth unless it's an anonymous user, in which case we must use a google service account JWT. This JWT holds a google client access token used by google in determining permissions.
Once the client is set up we can start making drive requests on behalf of the user getting their drive content inside the web app including folders, files, documents, pictures, shared drives and so on, which can later be rendered on a page.
These requests are a bottleneck, which required many optimizations and concurrency tricks to make the site considerably faster than the competition.

The storage API uses Prisma ORM for storing and getting all the user info including wikis and spaces. When a user logs in they can see their wiki as well as all the wikis they are allowed to manage. It's used to handle authorized requests like changing the wiki/space name, url, permissions and more. Storage is an integral part of any web application.

The UI/UX uses TailwindCSS and DaisyUI to make everything a fast, modern, optimized and intuitive experience with extra features like dozens of themes as well as a custom theme builder.
React was used with TypeScript to provide a nice modern client-side experience between transitions and interactions.
This setup supports maximum optimization as you can see in the screenshots below allowing the app to reach a lighthouse score of 100 on all but one (it has 99) pages.
Both mobile and desktop is supported.


---


### Technical details

First install [googleapis](https://www.npmjs.com/package/googleapis)

```bash
bun i googleapis
```



```ts
let authClient: Auth.GoogleAuth | Auth.OAuth2Client = new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET
);
authClient.setCredentials({
  access_token: jwt.accessToken?.value,
  refresh_token: jwt.user?.refreshToken,
});
```

