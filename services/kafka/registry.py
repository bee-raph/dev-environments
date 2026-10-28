#!/usr/bin/env python3
"""Generate a temporary schema-registry admin auth file, then start Karapace."""
import base64
import hashlib
import json
import os
import secrets
import sys
import urllib.request


def request(path, method='GET', value=None):
    token = base64.b64encode(('developer:' + os.environ['DEVELOPER_PASSWORD']).encode()).decode()
    data = None if value is None else json.dumps(value).encode()
    req = urllib.request.Request('http://127.0.0.1:8081' + path, method=method, data=data,
                                 headers={'Authorization': 'Basic ' + token, 'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=15) as response:
        return json.load(response)


if len(sys.argv) > 1 and sys.argv[1] == 'health':
    request('/subjects')
    sys.exit(0)
salt = secrets.token_hex(16)
hashed = base64.b64encode(hashlib.pbkdf2_hmac('sha512', os.environ['DEVELOPER_PASSWORD'].encode(), salt.encode(), 5000)).decode()
config = {'users': [{'username': 'developer', 'algorithm': 'sha512', 'salt': salt, 'password_hash': hashed}],
          'permissions': [{'username': 'developer', 'operation': 'Write', 'resource': '.*'}]}
os.umask(0o077)
with open('/tmp/registry-auth.json', 'w') as file:
    json.dump(config, file)
os.execvp('python3', ['python3', '-m', 'karapace'])
