#!/bin/sh
# need node v14
npm install
./node_modules/.bin/hexo clean
./node_modules/.bin/hexo generate
./node_modules/.bin/hexo server