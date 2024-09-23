---
title: Remotely profiling a Tomcat process serving a Java app
goal: To enable Java profiling on a Tomcat server running on CentOS and then optimize the process using VM options.
role:
date: Nov 2023
z: 8
author: Ivan Dimitrov
published: Nov 2023
---

[VisualVM](https://visualvm.github.io/) is a FOSS Java profiler used to monitor the resource usage of an app. It can be very useful when you want to diagnose problems with your
program and/or optimize it.

[For Java VM optimizations, please have a look here](https://stackoverflow.com/questions/564039/jvm-performance-tuning-for-large-applications).

### Technical details

Remote Java profiling is natively supported through the use of [JMX technology](https://docs.oracle.com/javase/8/docs/technotes/guides/management/agent.html). To use it, you tell
the JVM to start with JMX enabled by adding some startup options to your application.

By default, this is a localhost only solution which lets you profile while developing an app. Using this over the network requires extra steps of securing the connection as it's
not encrypted and it doesn't have a password.

To encrypt the connection you need to create 2 pairs of keystores and truststores for both Tomcat and VisualVM and then make sure that they trust each other (using -import).

At the end you'll end up with something like this for the JAVA_OPTS definition

```bash
# ... your catalina.sh
add_opt() {
        export JAVA_OPTS="$JAVA_OPTS $1"
}

conf_dir="/path/to/tomcat/conf"
my_pass="changeme"

add_opt "-Dcom.sun.management.jmxremote"
add_opt "-Dcom.sun.management.jmxremote.port=9090"
add_opt "-Dcom.sun.management.jmxremote.rmi.port=9090"
add_opt "-Djava.rmi.server.hostname=example.com"
add_opt "-Djava.net.preferIPv4Stack=true"

add_opt "-Dcom.sun.management.jmxremote.authenticate=true"
add_opt "-Dcom.sun.management.jmxremote.password.file=$conf_dir/jmxremote.password"
add_opt "-Dcom.sun.management.jmxremote.access.file=$conf_dir/jmxremote.access"

add_opt "-Dcom.sun.management.jmxremote.ssl=true"
add_opt "-Dcom.sun.management.jmxremote.registry.ssl=true"
add_opt "-Dcom.sun.management.jmxremote.ssl.need.client.auth=true"
add_opt "-Djavax.net.ssl.keyStore=$conf_dir/tomcat.keystore"
add_opt "-Djavax.net.ssl.keyStorePassword=$my_pass"
add_opt "-Djavax.net.ssl.trustStore=$conf_dir/tomcat.truststore"
add_opt "-Djavax.net.ssl.trustStorePassword=$my_pass"
# ... your catalina.sh
```

and you'll have something like this for the keystore and truststore generation

```bash
#!/usr/bin/env bash

dname="cn=myname, ou=mygroup, o=mycompany, c=mycountry"
pass="changeme"

keytool -genkey -alias tomcat -keyalg RSA -validity 365 -keystore tomcat.keystore -storepass "$pass" -keypass "$pass" -dname "$dname"
keytool -genkey -alias tomcat -keyalg RSA -validity 365 -keystore tomcat.truststore -storepass "$pass" -keypass "$pass" -dname "$dname"

keytool -genkey -alias vvm -keyalg RSA -validity 365 -keystore vvm.keystore -storepass "$pass" -keypass "$pass" -dname "$dname"
keytool -genkey -alias vvm -keyalg RSA -validity 365 -keystore vvm.truststore -storepass "$pass" -keypass "$pass" -dname "$dname"

keytool -export -alias tomcat -keystore tomcat.keystore -file tomcat.cer -storepass "$pass"
keytool -export -alias vvm -keystore vvm.keystore -file vvm.cer -storepass "$pass"

keytool -import -alias jconsole -file vvm.cer -keystore tomcat.truststore -storepass "$pass" -noprompt
keytool -import -alias tomcat -file tomcat.cer -keystore vvm.truststore -storepass "$pass" -noprompt
```

This last script will generate 6 files 2 of which are temporary and can be deleted (the .cer files).

To later use these files and make a connection you need to restart your Tomcat server and run VisualVM like so:

```bash
#!/usr/bin/env bash
pass="whatever_you_set_as_password_for_the_keystore_in_the_script"
visualvm -J-Djavax.net.ssl.keyStore=/path/to/vvm.keystore -J-Djavax.net.ssl.keyStorePassword=$pass -J-Djavax.net.ssl.trustStore=/path/to/vvm.truststore -J-Djavax.net.ssl.trustStorePassword=$pass
```

As for the actual VisualVM UI - I'm sure you'll figure it out since you already found your way here.

### Explanation

This enables JMX on port 9090 together with the RMI option. RMI is required for the remote connection.

```bash
add_opt "-Dcom.sun.management.jmxremote"
add_opt "-Dcom.sun.management.jmxremote.port=9090"
add_opt "-Dcom.sun.management.jmxremote.rmi.port=9090"
add_opt "-Djava.rmi.server.hostname=example.com" # Optional - sometimes it works without this and sometimes it doesn't
add_opt "-Djava.net.preferIPv4Stack=true" # Uses IPv4 instead of IPv6
```

This adds a username/password authentication to the JMX connection.

```bash
add_opt "-Dcom.sun.management.jmxremote.authenticate=true"
add_opt "-Dcom.sun.management.jmxremote.password.file=$conf_dir/jmxremote.password"
add_opt "-Dcom.sun.management.jmxremote.access.file=$conf_dir/jmxremote.access"
```

The jmxremote.password file is in this format:

```
role1 pass1
role2 pass2
role3 pass3
```

And the jmxremote.access file is in this format:

```
role1 readonly
role2 readwrite
role3 readwrite
```

`readonly` can only monitor the program whereas `readwrite` can also issue commands like "Perform GC" etc.

This enables and makes SSL a requirement for the connection.

```bash
add_opt "-Dcom.sun.management.jmxremote.ssl=true"
add_opt "-Dcom.sun.management.jmxremote.registry.ssl=true" # Very important line - doesn't work without it. Don't know why.
add_opt "-Dcom.sun.management.jmxremote.ssl.need.client.auth=true"
add_opt "-Djavax.net.ssl.keyStore=$conf_dir/tomcat.keystore" # The tomcat.keystore file generated through the script above.
add_opt "-Djavax.net.ssl.keyStorePassword=$my_pass" # Whatever you set the keystore password to in the script.
add_opt "-Djavax.net.ssl.trustStore=$conf_dir/tomcat.truststore" # Same but truststore
add_opt "-Djavax.net.ssl.trustStorePassword=$my_pass" # Same
```
