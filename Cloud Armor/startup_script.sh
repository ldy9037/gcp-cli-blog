#!/bin/bash
sudo timedatectl set-timezone Asia/Seoul

if rpm -q nginx | grep "not installed" ; then
    sudo dnf update -y
    sudo dnf install -y nginx
fi

sudo systemctl enable nginx
sudo systemctl start nginx