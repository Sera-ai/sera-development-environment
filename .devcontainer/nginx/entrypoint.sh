apt-get update && apt-get install -y libbson-dev libmongoc-dev
luarocks install lua-mongo 

openresty -g daemon off; -c /etc/nginx/nginx.conf;