#!/usr/bin/python3

import asyncio
import os
import tempfile
from dotenv.main import get_key, set_key

envFile = "/etc/opt/compose/.env"

# created, restarting, running, removing, paused, exited and dead
async def get_container_status():
    program = [ 'docker', 'ps', '--format', '{{.Names}}:{{.State}}' ]
    p = await asyncio.create_subprocess_exec(*program, stdout=asyncio.subprocess.PIPE)
    stdout, stderr = await p.communicate()
    if p.returncode == 0:
        return extract_container_status(stdout.decode())
    else:
        print("error")

def extract_container_status(result):
    lines = result.split("\n")
    status = {}
    for line in lines:
        if len(line) > 0:
            line = line.split(':')
            status[line[0]] = line[1]
    return status

async def up(profile, recreate=False, service=None):
    program = [ 'docker', 'compose', '--env-file', envFile, '--profile', profile, 'up', '--detach' ]
    if recreate:
        program.append('--force-recreate')
    if service:
        program.append(service)
    p = await asyncio.create_subprocess_exec(*program, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE)
    stdout, stderr = await p.communicate()
    if p.returncode == 0:
        print(stdout.decode())
        print(stderr.decode())
    else:
        print("error")

def read_config_value(key):
    value = get_key(envFile, key)
    if len(value) == 0:
        value = None

    return value

def update_config_value(key, value):
    # make sure the tmpfile is created in target dir to prevent mess due to the container
    tempfile.tempdir = os.path.dirname(envFile)
    #success, key, value = set_key(file, key, value, quote, export)
    set_key(envFile, key, value, 'never', False)
    # reset tempdir afterwards
    tempfile.tempdir = None
    # https://stackoverflow.com/a/10541972: NamedTemporaryFile is always created with mode 0600
    os.chmod(envFile, 0o666)

async def main():
    print('compose test')

    print (await get_container_status())
    await up('on')

if __name__ == '__main__':
    asyncio.run(main())
