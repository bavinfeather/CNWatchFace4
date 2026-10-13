"""Run release fixtures through the SDK's native simulator and retain output."""
from pathlib import Path
import argparse
import os
import re
import subprocess
import time

root = Path(__file__).resolve().parents[1]
sdk = Path((Path(os.environ['APPDATA']) / 'Garmin/ConnectIQ/current-sdk.cfg').read_text().strip())
parser = argparse.ArgumentParser()
parser.add_argument('task', choices=['lifecycle', 'power'])
parser.add_argument('devices', nargs='+')
args = parser.parse_args()
evidence = root / 'releases/1.0.0/evidence'
pattern = r'RELIABILITY PASSED frames=3000 sleepWake=30' if args.task == 'lifecycle' else r'POWER_PAIRED PASSED pairs=100'
for device in args.devices:
    if not re.fullmatch(r'\w+', device):
        raise ValueError('Invalid device ID')
    program = root / f'bin/release-{args.task}-{device}.prg'
    if not program.is_file():
        raise FileNotFoundError(program)
    log_path = evidence / f'{args.task}-{device}-runtime.log'
    with log_path.open('w', encoding='utf-8') as output:
        process = subprocess.Popen(['java', '-classpath', str(sdk / 'bin/monkeybrains.jar'),
            'com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux', '-f', str(program),
            '-d', device, '-s', str(sdk / 'bin/shell.exe')], cwd=root,
            stdout=output, stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW)
        deadline = time.monotonic() + 300
        try:
            while time.monotonic() < deadline:
                log = log_path.read_text(encoding='utf-8', errors='replace')
                if re.search(r'Unhandled|RELIABILITY FAILED|Encountered an app crash|Out Of Memory|Watchdog', log, re.I):
                    raise RuntimeError(f'{device}: native run failed; see {log_path}')
                if re.search(pattern, log):
                    print(f'{device}: {args.task} PASS', flush=True)
                    break
                if process.poll() is not None:
                    raise RuntimeError(f'{device}: exited without completion marker; see {log_path}')
                time.sleep(0.25)
            else:
                raise TimeoutError(f'{device}: native run timed out; see {log_path}')
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=10)
