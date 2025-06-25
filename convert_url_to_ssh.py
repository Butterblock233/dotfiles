import re
import sys

def convert_to_ssh(url: str) -> str:
    url = url.strip()
    match = re.match(r'^https://github\.com[:/]([^/]+)/([^/]+?)(\.git)?$', url)
    if match:
        user, repo = match[1], match[2]
        return f'git@github.com:{user}/{repo}.git'
    return ''

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('', end='')
        sys.exit(1)
    ssh_url = convert_to_ssh(sys.argv[1])
    print(ssh_url, end='')
