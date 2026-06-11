#!/bin/bash
sudo nginx
code-server --bind-addr 127.0.0.1:8080 --auth none /home/user/app &
python3 /home/user/app/relay.py &
wait
