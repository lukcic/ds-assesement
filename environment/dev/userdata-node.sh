#!/usr/bin/env bash
set -eu

cd /tmp

# Install and enable SSM Agent
wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
systemctl enable --now amazon-ssm-agent
systemctl status amazon-ssm-agent

# Install and configure Elasticsearch master
apt update 
apt install -y openjdk-17-jre jq
wget -q https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.11.1-amd64.deb
dpkg -i elasticsearch-${elastic_version}-amd64.deb

cat >> /etc/elasticsearch/elasticsearch.yml <<EOF
cluster.name: ${cluster_name}
node.name: $(hostname)
node.roles: [data]
network.host: _site_
discovery.seed_hosts: [${master_node_ips}]
EOF

sed -e 's/^cluster.initial_master_nodes:.*/#cluster.initial_master_nodes: [${master_node_ips}]/g' -i /etc/elasticsearch/elasticsearch.yml
sed -i 's/xpack.security.enabled: true/xpack.security.enabled: false/g' /etc/elasticsearch/elasticsearch.yml
sed -i 's/xpack.security.enrollment.enabled: true/xpack.security.enrollment.enabled: false/g' /etc/elasticsearch/elasticsearch.yml

systemctl enable --now elasticsearch.service
curl -XGET 'http://localhost:9200/_cluster/health?wait_for_status=yellow' | jq
