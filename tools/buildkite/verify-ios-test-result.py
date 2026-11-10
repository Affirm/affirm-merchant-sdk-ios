#!/usr/bin/env python3
"""Reject skipped, missing, or failing tests even if xcodebuild returned zero."""
import json
import sys


def verify(data: dict) -> None:
    metrics = data.get('metrics', {})
    counts = {key: int(metrics.get(key, {}).get('_value', 0)) for key in ('testsCount', 'testsFailedCount', 'testsSkippedCount')}
    if counts != {'testsCount': 1, 'testsFailedCount': 0, 'testsSkippedCount': 0}:
        raise ValueError(f'Expected exactly one passing, non-skipped SDK promo test: {counts}')
    print('Verified one passing SDK promo simulator test, zero skipped tests')


if __name__ == '__main__':
    with open(sys.argv[1]) as handle:
        verify(json.load(handle))
