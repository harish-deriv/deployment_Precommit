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
