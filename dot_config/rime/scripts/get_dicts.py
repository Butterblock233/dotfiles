import os

import requests
import hashlib
from pathlib import Path
import concurrent.futures
from tqdm import tqdm
import sys
import io

# Force stdout to use UTF-8 encoding
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')


# GitHub 仓库信息

# GitHub API 获取目录内容
API_URL = "https://api.github.com/repos/gaboolic/rime-frost/contents/cn_dicts"

HEADERS = {
    "Accept": "application/vnd.github.v3+json"
}

# 本地保存路径（Rime 的 build 目录）
LOCAL_DIR = Path.home() / ".config" / "rime" / "remote_cn_dicts"


def get_remote_files()->list:
    """从 GitHub 获取词库文件列表"""
    response = requests.get(API_URL, headers=HEADERS)
    if response.status_code != 200:
        raise Exception("无法从 GitHub 获取文件列表")

    files = []
    for item in response.json():
        if item["name"].endswith(".dict.yaml"):
            files.append({
                "name": item["name"],
                "url": item["download_url"],
                "sha": item["sha"]
            })
    return files


def file_hash(file_path):
    """计算文件的 SHA1 哈希值 (与 Git 一致)"""
    if not os.path.exists(file_path):
        return None
    with open(file_path, "rb") as f:
        # Git's blob hash is SHA1 of "blob <size>\0<content>"
        content = f.read()
        header = f"blob {len(content)}\0".encode('utf-8')
        return hashlib.sha1(header + content).hexdigest()


def download_file(file_info):
    """下载单个文件"""
    url = file_info["url"]
    filename = LOCAL_DIR / file_info["name"]
    response = requests.get(url)
    with open(filename, "wb") as f:
        f.write(response.content)
    return f"已下载: {filename.name}"


def sync_dict_files():
    """主函数：同步词库文件"""
    LOCAL_DIR.mkdir(parents=True, exist_ok=True)

    print("正在获取远程文件列表...")
    remote_files = get_remote_files()

    files_to_download = []
    for item in remote_files:
        local_path = LOCAL_DIR / item["name"]
        local_hash = file_hash(local_path)

        # GitHub API v3 returns SHA1 hashes for blobs
        if local_hash != item["sha"]:
            print(f"需要更新: {item['name']}")
            files_to_download.append(item)
        else:
            print(f"无需更新: {item['name']}")

    if not files_to_download:
        print("所有文件都是最新的。")
        return

    print(f"\n准备下载 {len(files_to_download)} 个文件...")
    # 使用线程池并发下载
    with concurrent.futures.ThreadPoolExecutor() as executor:
        results = list(tqdm(executor.map(download_file, files_to_download), total=len(files_to_download), desc="下载进度"))

    for result in results:
        print(result)


if __name__ == "__main__":
    sync_dict_files()
