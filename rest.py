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
    app.run(port=8080, debug=True)
