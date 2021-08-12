#!/bin/bash
set -e

apt-get update
apt-get upgrade -y 

apt-get install python-pip -y
pip install flask-restful

ufw allow 22
ufw allow 80
ufw allow 8080
ufw default deny incoming
ufw enable

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

usermod -aG docker ubuntu

mkdir -p /data
cat << EOF > /data/index.html
Welcome!<br>
Resource log: http://\$(curl -s http://checkip.amazonaws.com/)/resource.html<br>
Rest API: http://\$(curl -s http://checkip.amazonaws.com/):8080/search/&lt;query&gt;<br>
     eg: http://\$(curl -s http://checkip.amazonaws.com/):8080/search/nginx<br>
EOF

docker run -d --name "nginx" -p 80:80 -v /data:/usr/share/nginx/html:ro nginx

sleep 10s

cat << EOF > /usr/bin/health.sh
#!/bin/bash

while true; do
  datetime=\$(date "+%F %r %z")
  health=\$(docker stats nginx --no-stream --format "name={{ .Name }} cpu={{ .CPUPerc }} mem={{ .MemPerc }} net={{ .NetIO }} block={{ .BlockIO }}")

  echo "\$${datetime} \$${health}" >> /var/log/resource.log
  echo "\$${datetime} \$${health}<br>" >> /data/resource.html
  sleep 10s
done
EOF

cat << EOF > /usr/bin/rest.py
#!/usr/bin/python
from flask import Flask
from flask_restful import Resource, Api

app = Flask(__name__)
api = Api(app)

class Search(Resource):
    def get(self, query):
        result = []
        with open('/var/log/resource.log') as f:
            datafile = f.readlines()
        for line in datafile:
            if query in line:
                result.append(line)
        return {"Query": query, "Result": result}

api.add_resource(Search, '/search/<string:query>')

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080, debug=True)
EOF

chmod +x /usr/bin/health.sh
chmod +x /usr/bin/rest.py

nohup /usr/bin/health.sh &>/dev/null &
nohup /usr/bin/rest.py &>/dev/null &

sleep 10

exit 0
