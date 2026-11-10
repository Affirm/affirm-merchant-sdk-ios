#!/usr/bin/env python3
"""Set the XCTest runner environment explicitly; host shell exports are insufficient."""
from __future__ import annotations

import os
import plistlib
import sys
from pathlib import Path


def configure(path: Path, environment: dict[str, str]) -> None:
    with path.open('rb') as handle:
        data = plistlib.load(handle)
    if data.get('__xctestrun_metadata__', {}).get('FormatVersion', 1) == 2:
        targets = [target for config in data['TestConfigurations'] for target in config['TestTargets']]
    else:
        targets = [value for key, value in data.items() if not key.startswith('__') and isinstance(value, dict)]
    matched = [target for target in targets if 'ExamplesUITests' in str(target.get('TestBundlePath', ''))]
    if len(matched) != 1:
        raise ValueError(f'Expected one ExamplesUITests target in {path}, got {len(matched)}')
    matched[0].setdefault('EnvironmentVariables', {}).update(environment)
    with path.open('wb') as handle:
        plistlib.dump(data, handle)


if __name__ == '__main__':
    keys = ('AFFIRM_PROMO_BASE_URL', 'AFFIRM_PUBLIC_KEY', 'AFFIRM_EXPECTED_PROMO_TEXT',
            'AFFIRM_PROMO_EXTERNAL_ID', 'AFFIRM_COUNTRY_CODE', 'AFFIRM_LOCALE', 'AFFIRM_CURRENCY')
    env = {key: os.environ[key] for key in keys if key in os.environ}
    for key in ('AFFIRM_PROMO_BASE_URL', 'AFFIRM_PUBLIC_KEY', 'AFFIRM_EXPECTED_PROMO_TEXT'):
        if not env.get(key):
            raise ValueError(f'Missing {key}')
    configure(Path(sys.argv[1]), env)
