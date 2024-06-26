#!/bin/bash
sudo timedatectl set-timezone Asia/Seoul

if ! rpm -q nginx ; then
    sudo dnf update
    sudo dnf install -y nginx
fi

sudo systemctl enable nginx
sudo systemctl start nginx