#!/bin/bash

set -e

JDK_VER="11.0.8"
JDK_BUILD="10"
JDK_BUILD_SHORT="10"
PACKR_VERSION="runelite-1.3"

if ! [ -f OpenJDK11U-jre_x64_windows_hotspot_${JDK_VER}_${JDK_BUILD}.zip ] ; then
    curl -Lo OpenJDK11U-jre_x64_windows_hotspot_${JDK_VER}_${JDK_BUILD}.zip \
        https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-${JDK_VER}%2B${JDK_BUILD}/OpenJDK11U-jre_x64_windows_hotspot_${JDK_VER}_${JDK_BUILD_SHORT}.zip
fi

echo "fefa05395dbccfe072a8b6fbfebecf797ed81e18cb1aa4ed093c653d316b3f56 OpenJDK11U-jre_x64_windows_hotspot_${JDK_VER}_${JDK_BUILD}.zip" | sha256sum -c

# packr requires a "jdk" and pulls the jre from it - so we have to place it inside
# the jdk folder at jre/
if ! [ -d win64-jdk ] ; then
    unzip OpenJDK11U-jre_x64_windows_hotspot_${JDK_VER}_${JDK_BUILD}.zip
    mkdir win64-jdk
    mv jdk-$JDK_VER+$JDK_BUILD_SHORT-jre win64-jdk/jre
fi

if ! [ -f packr_${PACKR_VERSION}.jar ] ; then
    curl -Lo packr_${PACKR_VERSION}.jar \
        https://github.com/runelite/packr/releases/download/${PACKR_VERSION}/packr.jar
fi

echo "f200fb7088dbb5e61e0835fe7b0d7fc1310beda192dacd764927567dcd7c4f0f  packr_${PACKR_VERSION}.jar" | sha256sum -c

java -jar packr_${PACKR_VERSION}.jar \
    --platform \
    windows64 \
    --jdk \
    win64-jdk \
    --executable \
    OpenOSRS \
    --classpath \
    build/libs/OpenOSRS-shaded.jar \
    --mainclass \
    net.runelite.launcher.Launcher \
    --vmargs \
    Drunelite.launcher.nojvm=true \
    Xmx512m \
    Xss2m \
    XX:CompileThreshold=1500 \
    Djna.nosys=true \
    --output \
    native-win64

# modify packr exe manifest to enable Windows dpi scaling
"C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" \
    -open native-win64/OpenOSRS.exe \
    -save native-win64/OpenOSRS.exe \
    -action addoverwrite \
    -res packr/openosrs.manifest \
    -mask MANIFEST,1,

# packr on Windows doesn't support icons, so we use resourcehacker to include it
"C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe" \
    -open native-win64/OpenOSRS.exe \
    -save native-win64/OpenOSRS.exe \
    -action add \
    -res openosrs.ico \
    -mask ICONGROUP,MAINICON,

if ! [ -f vcredist_x64.exe ] ; then
    # Visual C++ Redistributable for Visual Studio 2015
    curl -Lo vcredist_x64.exe https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe
fi

echo "5eea714e1f22f1875c1cb7b1738b0c0b1f02aec5ecb95f0fdb1c5171c6cd93a3 *vcredist_x64.exe" | sha256sum -c

# We use the filtered iss file
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" build/filtered-resources/openosrs.iss