#!/bin/bash

# Function to install Java 8 using the default package repository
install_default() {
  echo "Updating package index..."
  sudo apt update
  echo "Installing OpenJDK 8..."
  sudo apt install -y openjdk-8-jdk
}

# Function to install Java 8 using a PPA
install_ppa() {
  echo "Adding the PPA repository..."
  sudo add-apt-repository -y ppa:webupd8team/java
  sudo apt update
  echo "Installing Oracle Java 8..."
  sudo apt install -y oracle-java8-installer
  sudo apt install -y oracle-java8-set-default
}

# Function to set JAVA_HOME environment variable
set_java_home() {
  JAVA_HOME_PATH=$(sudo update-alternatives --config java | grep 'java-8-' | awk '{print $3}' | xargs dirname | xargs dirname)
  echo "Setting JAVA_HOME to $JAVA_HOME_PATH"
  sudo sed -i '/JAVA_HOME/d' /etc/environment
  echo "JAVA_HOME=\"$JAVA_HOME_PATH\"" | sudo tee -a /etc/environment
  source /etc/environment
  echo "JAVA_HOME set to $JAVA_HOME"
}

# Function to verify the installation
verify_installation() {
  echo "Verifying Java installation..."
  java -version
}

# Main script logic
echo "Checking available installation methods for Java 8..."

# Check if OpenJDK 8 is available in the default repository
if apt-cache show openjdk-8-jdk > /dev/null 2>&1; then
  echo "OpenJDK 8 is available in the default package repository."
  install_default
else
  echo "OpenJDK 8 is not available in the default package repository. Trying PPA method..."
  
  # Add the PPA and check if Oracle Java 8 is available
  sudo add-apt-repository -y ppa:webupd8team/java
  sudo apt update
  
  if apt-cache show oracle-java8-installer > /dev/null 2>&1; then
    echo "Oracle Java 8 is available in the PPA."
    install_ppa
  else
    echo "Neither OpenJDK 8 nor Oracle Java 8 are available. Exiting."
    exit 1
  fi
fi

set_java_home
verify_installation

echo "Java 8 installation and setup completed."
