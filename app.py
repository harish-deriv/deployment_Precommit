import csv
import os
import random
import string
from flask import Flask, request, jsonify
from slack_sdk.webhook import WebhookClient
from dotenv import load_dotenv

# Initializing ".env" variables
load_dotenv()

app = Flask(__name__)

URL = os.getenv('SLACK_WEBHOOK')
AUTH_TOKEN = os.getenv('AUTH_TOKEN')
TEST_SUCCESS_MD5='8fab2cca7d6927a6f5f7c866db28ce3e'
RED='#b90909'
GREEN='#09b912'

def slack_notification(URL, serial_number=None, username=None, message=None, color=None):
    webhook = WebhookClient(URL)

    response = webhook.send(
                text="Precommit Deployment Alert", 
                attachments=[
                    {
                        "color": color,
                        "author_name": f"{message}\n",
                        "fields": [{"value": f"Username: {username}\nSerial number: {serial_number}"}], 
                    }
                ]
            )

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

# Use to test ELB connection 
@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({'message': 'pong'}), 200


if __name__ == '__main__':
    app.run(host="0.0.0.0",port=8443,ssl_context=('cert.pem','key.pem'))
