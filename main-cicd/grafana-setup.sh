#!/bin/bash
# Hardware requirements: Ubuntu 20.04 instance with mimum t2.micro type instance & port 3000 (grafana), 9100 (node-exporter) should be allowed on the security groups
sudo apt-get install -y adduser libfontconfig1
sudo wget https://dl.grafana.com/oss/release/grafana_7.3.4_amd64.deb
sudo dpkg -i grafana_7.3.4_amd64.deb
sudo systemctl daemon-reload
sudo systemctl start grafana-server
sudo systemctl status grafana-server
sudo systemctl enable grafana-server.service

#!/bin/bash

# Define the latest Node Exporter version
NODE_EXPORTER_VERSION="X.Y.Z"

# node-exporter installations
sudo useradd --no-create-home node_exporter

# Download and install the latest Node Exporter
wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" -P /tmp
tar xzf "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" -C /tmp
sudo cp "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/node_exporter
rm -rf "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"

# Setup the node-exporter systemd service
sudo git clone -b installations https://github.com/cvamsikrishna11/devops-fully-automated.git /tmp/devops-fully-automated
sudo cp "/tmp/devops-fully-automated/prometheus-setup-dependencies/node-exporter.service" /etc/systemd/system/node-exporter.service

sudo systemctl daemon-reload
sudo systemctl enable node-exporter
sudo systemctl start node-exporter
sudo systemctl status node-exporter
