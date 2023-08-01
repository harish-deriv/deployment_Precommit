import csv
import os
import random
import string
from flask import Flask, request, jsonify

app = Flask(__name__)

AUTH_TOKEN = "TOKEN"

def generate_random_string(length):
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))

@app.route('/endpoint', methods=['POST'])
def notify():
    if request.headers.get('Authorization') != AUTH_TOKEN:
        return jsonify({'message': 'Authorization failed'}), 401

    data = {
        'serial_number': request.form.get('serial_number'),
        'username': request.form.get('username')
    }

    with open('data.csv', mode='a') as csv_file:
        fieldnames = ['serial_number', 'username']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writerow(data)

    return jsonify({'message': 'success'}), 200

if __name__ == '__main__':
    app.run(host="0.0.0.0",port=8443,ssl_context=('cert.pem','key.pem'))
import csv
import os
import random
import string
from flask import Flask, request, jsonify

app = Flask(__name__)

AUTH_TOKEN = "TOKEN"

def generate_random_string(length):
    letters = string.ascii_lowercase
    return ''.join(random.choice(letters) for i in range(length))

# Linux Deployment Script Endpoint
@app.route('/linux-endpoint', methods=['POST'])
def linux_notify():
    if request.headers.get('Authorization') != AUTH_TOKEN:
        return jsonify({'message': 'Authorization failed'}), 401

    data = {
        'serial_number': request.form.get('serial_number'),
        'username': request.form.get('username')
    }

    with open('linux_data.csv', mode='a') as csv_file:
        fieldnames = ['serial_number', 'username']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writerow(data)

    return jsonify({'message': 'success'}), 200

# MacBook Deployment Script Endpoint
# eg. curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user&exit_code=$precommit_exit_code&message=$message" https://REPLACE_WITH_ELB:8443/mac-<replace with random endpoint> -k -H "Authorization: token" 
@app.route('/mac-endpoint', methods=['POST'])
def mac_notify():
    if request.headers.get('Authorization') != AUTH_TOKEN:
        return jsonify({'message': 'Authorization failed'}), 401

    data = {
        'serial_number': request.form.get('serial_number'),
        'username': request.form.get('username'),
        'exit_code': request.form.get('exit_code'),
        'message': request.form.get('message')
    }

    with open('mac_data.csv', mode='a') as csv_file:
        fieldnames = ['serial_number', 'username', 'exit_code', 'message']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writerow(data)

    return jsonify({'message': 'success'}), 200

# Use to test ELB connection 
@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({'message': 'pong'}), 200


if __name__ == '__main__':
    app.run(host="0.0.0.0",port=8443,ssl_context=('cert.pem','key.pem'))
