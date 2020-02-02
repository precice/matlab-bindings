FROM ubuntu:18.04

USER root

# Matlab dependencies
ENV DEBIAN_FRONTEND=noninteractive 
RUN apt-get update && apt-get install -y \
    ca-certificates \
    lsb-release \
    libasound2 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcap2 \
    libcomerr2 \
    libcups2 \
    libdbus-1-3 \
    libfontconfig1 \
    libgconf-2-4 \
    libgcrypt20 \
    libgdk-pixbuf2.0-0 \
    libgssapi-krb5-2 \
    libgstreamer-plugins-base1.0-0 \
    libgstreamer1.0-0 \
    libgtk2.0-0 \
    libk5crypto3 \
    libkrb5-3 \
    libnspr4 \
    libnspr4-dbg \
    libnss3 \
    libpam0g \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libpangoft2-1.0-0 \
    libselinux1 \
    libsm6 \
    libsndfile1 \
    libudev1 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxft2 \
    libxi6 \
    libxmu6 \
    libxrandr2 \
    libxrender1 \
    libxslt1.1 \
    libxss1 \
    libxt6 \
    libxtst6 \
    libxxf86vm1 \
    xkb-data \
    xvfb \
    x11vnc \
    xvfb \
    sudo \
    zlib1g \
    gcc \
    g++ \
    gfortran \
    unzip \
    tmux

# Add MATLAB installation files
ADD matlab-installer.zip /matlab-installer.zip
RUN unzip /matlab-installer.zip -d matlab-installer && \
    rm /matlab-installer.zip

# Add user 'precice', to choose within the MATLAB installation
RUN useradd -ms /bin/bash precice
USER precice
WORKDIR /home/precice
RUN mkdir MATLAB