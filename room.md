---
title: Room
description: Lab room for tests
---

<div id="myapp"></div>
<script src="/js/app.js"></script>
<script>
  var tokenKey = "auth_token";
  var app = Elm.Main.init({
    node: document.getElementById("myapp"),
    flags: localStorage.getItem(tokenKey)
  });
  app.ports.storeToken.subscribe(function(token) {
    localStorage.setItem(tokenKey, token);
  });
  app.ports.clearToken.subscribe(function() {
    localStorage.removeItem(tokenKey);
  });
</script>
