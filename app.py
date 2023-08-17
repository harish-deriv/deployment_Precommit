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
AUTH_TOKEN = "TOKEN"
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

# MacBook Deployment Script Endpoint
# eg. curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user&brew_installed=<Error Message> | none>&trufflehog_installed=<Error Message> | none>" https://REPLACE_WITH_ELB:8443/mac-<replace with random endpoint> -k -H "Authorization: token" 
@app.route('/mac-endpoint', methods=['POST'])
def mac_notify():
    if request.headers.get('Authorization') != AUTH_TOKEN:
        return jsonify({'message': 'Authorization failed'}), 401

    data = {
        'serial_number': request.form.get('serial_number'),
        'username': request.form.get('username'),
        'brew_installed': request.form.get('brew_installed'),
        'trufflehog_installed': request.form.get('trufflehog_installed'),
    }

    if data['brew_installed'] == 'BREW_NOT_INSTALLED':
        slack_notification(URL, serial_number=data['serial_number'], username=data['username'], message='Brew not Installed', color=RED)

    if data['trufflehog_installed'] == 'TRUFFLEHOG_NOT_INSTALLED':
        slack_notification(URL, serial_number=data['serial_number'], username=data['username'], message='Trufflehog not Installed', color=RED)
        
    with open('mac_data.csv', mode='a') as csv_file:
        fieldnames = ['serial_number', 'username', 'brew_installed', 'trufflehog_installed']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writerow(data)

    return jsonify({'message': 'success'}), 200

# eg. curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user&test_log_md5=<Insert md5 hash test log>" https://REPLACE_WITH_ELB:8443/mac-test-log-<replace with random endpoint> -k -H "Authorization: token" 
@app.route('/mac-test-log-endpoint', methods=['POST'])
def mac_notify_test_log():
    if request.headers.get('Authorization') != AUTH_TOKEN:
        return jsonify({'message': 'Authorization failed'}), 401

    data = {
        'serial_number': request.form.get('serial_number'),
        'username': request.form.get('username'),
    }

    if TEST_SUCCESS_MD5 == request.form.get('test_log_md5'):
        data['status'] = 'Success'
        slack_notification(URL, serial_number=data['serial_number'], username=data['username'], message='Pre-commit Configured Successfully', color=GREEN)
    else:
        data['status'] = 'Fail'
        slack_notification(URL, serial_number=data['serial_number'], username=data['username'], message='Pre-commit Configured Failed', color=RED)


    with open('mac_data_test_log.csv', mode='a') as csv_file:
        fieldnames = ['serial_number', 'username', 'status']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writerow(data)

    return jsonify({'message': 'success'}), 200

# eg. curl -X POST -d "serial_number=$SERIAL_NUMBER&user_log_base64=<Insert Base64 user log>" https://REPLACE_WITH_ELB:8443/mac-log-<replace with random endpoint> -k -H "Authorization: token" 
@app.route('/mac-log-endpoint', methods=['POST'])
def mac_notify_log():
    if request.headers.get('Authorization') != AUTH_TOKEN:
        return jsonify({'message': 'Authorization failed'}), 401

    data = {
        'serial_number': request.form.get('serial_number'),
        'user_log_base64': request.form.get('user_log_base64'),
    }
        
    with open('mac_data_log.csv', mode='a') as csv_file:
        fieldnames = ['serial_number', 'user_log_base64']
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writerow(data)

    return jsonify({'message': 'success'}), 200



# Use to test ELB connection 
@app.route('/ping', methods=['GET'])
def ping():
    return jsonify({'message': 'pong'}), 200


if __name__ == '__main__':
    app.run(host="0.0.0.0",port=8443,ssl_context=('cert.pem','key.pem'))
