#!/usr/bin/env python3
"""Select an installed iOS runtime rather than pinning a hosted-runner OS patch."""
import json
import subprocess
import sys


def read_simctl(kind):
    return json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', kind, '--json']))[kind]


def available_ios():
    return [runtime for runtime in read_simctl('runtimes')
            if runtime.get('isAvailable') and '.iOS-' in runtime['identifier']]


runtimes = available_ios()
if not runtimes:
    subprocess.run(['xcodebuild', '-downloadPlatform', 'iOS'], check=True, stdout=sys.stderr)
    runtimes = available_ios()
if not runtimes:
    raise SystemExit('No available iOS simulator runtime after platform installation')
runtime = max(runtimes, key=lambda item: tuple(int(part) for part in item['version'].split('.')))
devices = [device for device in read_simctl('devices').get(runtime['identifier'], [])
           if device.get('isAvailable') and device['name'].startswith('iPhone')]
if devices:
    device = max(devices, key=lambda item: (item['state'] == 'Booted', item['name'] == 'iPhone 17 Pro'))
    udid = device['udid']
    if device['state'] == 'Shutdown':
        subprocess.run(['xcrun', 'simctl', 'boot', udid], check=True, stdout=sys.stderr)
else:
    types = [item for item in read_simctl('devicetypes') if item['name'] == 'iPhone 17 Pro']
    if not types:
        raise SystemExit('No compatible iPhone simulator device type')
    udid = subprocess.check_output(['xcrun', 'simctl', 'create', 'AffirmSDK-CI',
                                    types[0]['identifier'], runtime['identifier']], text=True).strip()
    subprocess.run(['xcrun', 'simctl', 'boot', udid], check=True, stdout=sys.stderr)
subprocess.run(['xcrun', 'simctl', 'bootstatus', udid, '-b'], check=True, stdout=sys.stderr)
print('platform=iOS Simulator,id=' + udid)
