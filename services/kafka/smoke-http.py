#!/usr/bin/env python3
"""Run via smoke-test.sh inside the registry image; never print credentials."""
import base64
import http.cookiejar
import json
import os
import re
import time
import urllib.error
import urllib.parse
import urllib.request

password = os.environ['DEVELOPER_PASSWORD']
token = base64.b64encode(('developer:' + password).encode()).decode()

def request(base, path, method='GET', body=None, auth=True):
    headers = {'Content-Type': 'application/json'}
    if auth:
        headers['Authorization'] = 'Basic ' + token
    data = None if body is None else json.dumps(body).encode()
    with urllib.request.urlopen(urllib.request.Request(base + path, data=data, method=method, headers=headers), timeout=20) as response:
        payload = response.read()
        return json.loads(payload) if payload else None

for base, path in [('http://schema-registry:8081', '/subjects'), ('http://kafka-connect:8083', '/connectors')]:
    try:
        request(base, path, auth=False)
    except urllib.error.HTTPError as error:
        assert error.code == 401, error.code
    else:
        raise AssertionError('Unauthenticated API request succeeded')
print('Schema Registry and Connect reject unauthenticated requests.')
subject = 'developer-smoke-value'
schema = {'type': 'record', 'name': 'Smoke', 'fields': [{'name': 'message', 'type': 'string'}]}
try:
    registered = request('http://schema-registry:8081', '/subjects/' + subject + '/versions', 'POST', {'schema': json.dumps(schema)})
    latest = request('http://schema-registry:8081', '/subjects/' + subject + '/versions/latest')
    assert latest['id'] == registered['id']
    print('Schema registration/read passed.')
finally:
    request('http://schema-registry:8081', '/subjects/' + subject, 'DELETE')
    request('http://schema-registry:8081', '/subjects/' + subject + '?permanent=true', 'DELETE')
plugins = request('http://kafka-connect:8083', '/connector-plugins')
assert any(p['class'].endswith('FileStreamSinkConnector') for p in plugins), plugins
name = 'developer-smoke-sink'
try:
    request('http://kafka-connect:8083', '/connectors', 'POST', {'name': name, 'config': {
        'connector.class': 'org.apache.kafka.connect.file.FileStreamSinkConnector',
        'tasks.max': '1', 'topics': os.environ['SMOKE_TOPIC'], 'file': '/data/developer-smoke.txt',
        'key.converter': 'org.apache.kafka.connect.storage.StringConverter',
        'value.converter': 'org.apache.kafka.connect.storage.StringConverter',
        'consumer.override.auto.offset.reset': 'earliest'}})
    for attempt in range(60):
        try:
            status = request('http://kafka-connect:8083', '/connectors/' + name + '/status')
        except urllib.error.HTTPError as error:
            if error.code == 404:
                time.sleep(1)
                continue
            raise
        if status['tasks'] and all(t['state'] == 'RUNNING' for t in status['tasks']):
            break
        if any(t['state'] == 'FAILED' for t in status['tasks']):
            raise AssertionError(status)
        time.sleep(1)
    else:
        raise AssertionError('Connector did not reach RUNNING')
    # Wait for the consumer's initial assignment and first poll before removing it.
    time.sleep(8)
    print('Kafka Connect file-sink task reached RUNNING.')
finally:
    request('http://kafka-connect:8083', '/connectors/' + name, 'DELETE')
cookies = http.cookiejar.CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookies))
with opener.open('http://kafka-ui:8080/login', timeout=20) as response:
    page = response.read().decode()
csrf = re.search(r'name="_csrf"[^>]*value="([^"]+)"', page)
form = {'username': 'developer', 'password': password}
if csrf:
    form['_csrf'] = csrf.group(1)
with opener.open('http://kafka-ui:8080/login', data=urllib.parse.urlencode(form).encode(), timeout=20) as response:
    assert 'error' not in response.url, 'UI sign-in failed'
with opener.open('http://kafka-ui:8080/api/clusters', timeout=20) as response:
    clusters = json.load(response)
assert any(c['name'] == 'local' for c in clusters), clusters
print('Kafbat developer sign-in and cluster API passed.')
