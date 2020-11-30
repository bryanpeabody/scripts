#!/bin/bash

# CD to source directory and pull latest
cd /home/bryan/source/bpcom
git pull > /dev/null

# Move public to HTML
cp -r /home/bryan/source/bpcom/public/* /home/bryan/html

