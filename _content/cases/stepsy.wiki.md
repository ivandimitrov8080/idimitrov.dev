---
title: Multi-tenant knowledge base website integrated with Google Drive
goal: Implement a modern multi-tenant web app that interfaces with the Google API and lets users connect their Google Drive so that the content inside can be viewed in a wiki page
role: The developer who designed and implemented the entire project
---

A typical flow would look like this:

User logs in using Google
They go to the dashboard where they create a new wiki
After that they can create 1-many spaces under that wiki (a space is a Google Drive folder) and set permissions
Once connected and set up, anyone with the right permissions (even anonymous users if permitted) can view the content under the selected google drive folder in a modern wiki page.

The URL must match the following structure:
`https://<the name of the wiki>.stepsy.wiki/space/<the name of the space>`

This requires the following:

Server:
Authentication for admins and users
Storage and access to all related data
Some server-side processing to interface with the Google Drive API, the database and do some server-side rendering

Client:
Dashboard page for admins to create, read, update and delete wikis, spaces and permissions together with all related pages and forms.
Reader page for anyone with the right permissions can go through a space and read the content in a wiki-like page complete with modern styles. less


