#!/bin/bash

echo "Setting up llama.cpp for Android..."

# Create cpp directory if it doesn't exist
mkdir -p android/app/src/main/cpp

# Download llama.cpp source code
echo "Downloading llama.cpp source code..."
cd android/app/src/main/cpp

if [ ! -d "llama.cpp" ]; then
    git clone https://github.com/ggerganov/llama.cpp.git
    cd llama.cpp
    git checkout master
    echo "llama.cpp downloaded successfully"
else
    echo "llama.cpp already exists, updating..."
    cd llama.cpp
    git pull origin master
fi

# Copy necessary header files
echo "Setting up header files..."
cp llama.h ../
cp ggml.h ../
cp ggml-backend.h ../

echo "llama.cpp setup complete!"
echo "You can now build the Android app with real llama.cpp support." 