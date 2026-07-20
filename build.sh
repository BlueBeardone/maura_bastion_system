#!/bin/bash

# Clone the stable Flutter SDK repository
if [ -d "flutter" ]; then 
  cd flutter && git pull && cd ..
else 
  git clone https://github.com/flutter/flutter.git -b stable
fi

# Execute the build using the downloaded SDK
./flutter/bin/flutter config --enable-web
./flutter/bin/flutter build web --release
