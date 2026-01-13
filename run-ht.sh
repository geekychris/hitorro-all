#!/bin/bash

# Build first to ensure all dependencies are resolved
cd /home/chris/code/hitorro-all
mvn clean install -DskipTests

# Create directory if it doesn't exist
mkdir -p /home/chris/hitorro

# Run the application with proper classpath using Maven
cd /home/chris/hitorro
mvn -f /home/chris/code/hitorro-all/hitorro-app/pom.xml exec:java \
  -Dexec.mainClass="com.hitorro.util.cmdline.CommandLine" \
  -Dexec.args="command=com.hitorro.util.startupframework.HTServer servertype=test level=full dbinit=false network.disablelocalhostcheck=true multigram.enable=false sampleapp.fullui=true shutdown=false filesystem.fake.dir=\"/home/chris/code/hthome/fakehdfs\" loadprops=/home/chris/code/hitorro-all/testinput/configs" \
  -Dexec.classpathScope=runtime \
  -DHT_BIN=/home/chris/code/hitorro-all/ \
  -DHT_HOME="/home/chris/code/hthome" \
  -Xmx2010M
