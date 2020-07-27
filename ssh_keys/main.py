import subprocess
import tarfile
import docker
import time
import os
from io import BytesIO


client = docker.from_env()
containers = set()

def get_ssh_key(name, email, password, id):
    file_path = f'/keys/{name}'

    if not os.path.exists(file_path + '.pub'):
        print(f"\tGenerating SSH key for {name} ({id})")
        subprocess.run(['ssh-keygen', '-t', 'rsa', '-b', '4096', '-f', file_path, '-C', email, '-N', password])
        
    return name, file_path

def send_file(cnt, file_name, file_path, dest):
    size = os.stat(file_path).st_size

    with open(file_path, 'rb') as fp:
        pw_tarstream = BytesIO()
        pw_tar = tarfile.TarFile(fileobj=pw_tarstream, mode='w')
        tarinfo = tarfile.TarInfo(name=file_name)
        tarinfo.size = size
        tarinfo.mtime = time.time()
        pw_tar.addfile(tarinfo, fp)
        pw_tar.close()
    
    pw_tarstream.seek(0)
    print(f"\tSending {file_name}")
    cnt.put_archive(dest, pw_tarstream)

def parse_cnt(cnt):
    print(f"Detected new container {cnt.name} ({cnt.id})")

    needs_machine_fingerprint = False
    for name, value in cnt.labels.items():
        if name == 'ENABLE_SSH':
            # Signal we need to send it
            needs_machine_fingerprint = True

            # Generate user SSH key
            email, password = value.split(':', 1)
            ssh_name = email.replace('@', '_at_')
            ssh_name, ssh_path = get_ssh_key(ssh_name, email, password, cnt.id)
            print(f"\tSending SSH key to {cnt.name} ({cnt.id})")
            send_file(cnt, ssh_name + '.pub', ssh_path + '.pub', '/root/.ssh/')
            cnt.exec_run(f'/bin/bash -c "cat > /root/.ssh/authorized_keys < /root/.ssh/{ssh_name}.pub"')

    # Generate machine identity / ssh fingerprint
    if needs_machine_fingerprint:
        ssh_name, ssh_path = get_ssh_key(cnt.name + "_ssh_host_rsa_key", email, password, cnt.id)
        print(f"\tSending ssh_host_rsa_key key to {cnt.name} ({cnt.id})")
        send_file(cnt, 'ssh_host_rsa_key', ssh_path, '/etc/ssh/')
        send_file(cnt, 'ssh_host_rsa_key.pub', ssh_path + '.pub', '/etc/ssh/')

# Allow for some leeway
print("Starting")
time.sleep(1)
print("Scanning")

# Already running containers
for cnt in client.containers.list():
    parse_cnt(cnt)

try:
    # New containers
    for event in client.events(decode=True):
        if event.get('Type') == 'container':
            name = event.get("Actor", {}).get("Attributes", {}).get("com.docker.compose.service", event["id"])
            print(f'Got {event.get("status")} from {name}')
            if event.get('status') == 'start':
                parse_cnt(client.containers.get(event['id']))

except KeyboardInterrupt:
    pass
