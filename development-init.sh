#!/bin/sh

# vagrant gpg key 등록
if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
	wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
	echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
fi

# docker gpg key 등록
sudo mkdir -m 0755 -p /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

# apt update
sudo apt update

# clang install
sudo apt install -y clang

# llvm install
sudo apt install -y llvm

# docker install
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# vagrant install
sudo apt install -y vagrant

# pip3
sudo apt install -y python3-pip

# virtualbox install
# noninterative setting이 없음으로 수동 진행
sudo apt install -y virtualbox virtualbox-ext-pack

# golang 1.20 download
curl -fsSL https://go.dev/dl/go1.20.1.linux-amd64.tar.gz -o go1.20.1.linux-amd64.tar.gz

# golang install
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf ./go1.20.1.linux-amd64.tar.gz

# export
echo "export PATH=$PATH:/usr/local/go/bin" >> $HOME/.profile