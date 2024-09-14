#!/bin/bash

# 必要的变量
GH_REPO=$GH_REPO      # GitHub 私库名称 (e.g., user/repo)
GH_PAT=$GH_PAT        # GitHub 密钥
GH_BACKUP_USER=$GH_BACKUP_USER  # GitHub 用户名
GH_EMAIL=$GH_EMAIL    # GitHub 邮箱
DAYS=${DAYS:-5}       # 保留几天的备份文件
NAME=$NAME            # 备份项目名称
BACKUP_FILE=$BACKUP_FILE  # 自定义备份路径
SHOULD_STOP_PROJECT="false"  # 是否需要停止项目，默认不停止
USE_GPG="false" # 默认不启用 GPG 加密
GPG_KEY=""  # 如果启用加密，需提供密钥

# 时间戳
TIMESTAMP=$(date "+%Y-%m-%d-%H-%M")

# 检查 GitHub 私库连接是否有效
if ! curl --output /dev/null --silent --head --fail "$GH_API"; then
    echo "无法连接到 GitHub 私库"
    exit 1
fi

# 检查 GitHub 仓库是否存在
if ! curl --output /dev/null --silent --head --fail "$GH_UPLOAD_URL"; then
    echo "GitHub 仓库不存在"
    exit 1
fi

# 检查 GitHub 密钥是否有效
if ! curl --output /dev/null --silent --head --fail -H "Authorization: token $GH_PAT" "$GH_API/user"; then
    echo "GitHub 密钥无效"
    exit 1
fi

# 检查 GitHub 用户名和邮箱是否有效
if ! git config --get user.name >/dev/null || ! git config --get user.email >/dev/null; then
    echo "GitHub 用户名或邮箱未设置"
    exit 1
fi
# GitHub API 基础 URL
GH_API="https://api.github.com"
GH_UPLOAD_URL="https://$GH_BACKUP_USER:$GH_PAT@github.com/$GH_REPO.git"


stop_project() {
    echo "正在停止项目 $NAME..."
    # 假设这里是停止项目的命令，例如 systemctl 或 docker stop
    # 例如: systemctl stop "$NAME"
    echo "项目 $NAME 已停止"
}

start_project() {
    echo "正在启动项目 $NAME..."
    # 假设这里是启动项目的命令，例如 systemctl 或 docker start
    # 例如: systemctl start "$NAME"
    echo "项目 $NAME 已启动"
}

# 备份函数
backup() {
    echo "开始备份..."

    # 判断是否需要停止项目
    if [[ "$SHOULD_STOP_PROJECT" == "true" ]]; then
        stop_project
    fi

    # 判断是否需要 GPG 加密
    if [[ "$USE_GPG" == "true" ]]; then
        echo "对备份文件进行 GPG 加密..."
        gpg --yes --batch --output "$TMP_DIR/${TAR_NAME}.gpg" --encrypt --recipient "$GPG_KEY" "$TMP_DIR/$TAR_NAME"
        TAR_NAME="${TAR_NAME}.gpg"
    fi

    # 创建 /tmp 目录中的临时目录用于操作
    TMP_DIR=$(mktemp -d -t backup-XXXXXX)

    # 进入备份路径，创建压缩包
    cd "$BACKUP_FILE" || exit
    TAR_NAME="${NAME}_${TIMESTAMP}.tar.gz"
    tar -czf "$TMP_DIR/$TAR_NAME" .

    # 克隆私库到 /tmp 中
    git clone "$GH_UPLOAD_URL" "$TMP_DIR/repo"
    cd "$TMP_DIR/repo" || exit

    # 创建项目目录并确保只备份该项目的数据
    mkdir -p "$NAME"
    mv "$TMP_DIR/$TAR_NAME" "$NAME/"

    # 提交并推送备份文件
    git config user.name "$GH_BACKUP_USER"
    git config user.email "$GH_EMAIL"
    git add "$NAME/"
    git commit -m "备份 ${TAR_NAME} for project $NAME"
    git push

    # 删除过期备份
    find "$NAME/" -type f -mtime +$DAYS -exec git rm {} \;
    git commit -m "删除超过 $DAYS 天的备份 for project $NAME"
    git push

    # 删除临时目录
    rm -rf "$TMP_DIR"

    # 判断是否需要重新启动项目
    if [[ "$SHOULD_STOP_PROJECT" == "true" ]]; then
        start_project
    fi

    echo "备份完成: $TAR_NAME"
}


# 还原函数
restore() {
    echo "开始还原..."

    # 判断是否需要停止项目
    if [[ "$SHOULD_STOP_PROJECT" == "true" ]]; then
        stop_project
    fi


    # 创建 /tmp 目录中的临时目录用于操作
    TMP_DIR=$(mktemp -d -t restore-XXXXXX)

    # 克隆私库到 /tmp 中并强制获取最新内容
    git clone "$GH_UPLOAD_URL" "$TMP_DIR/repo"
    cd "$TMP_DIR/repo" || exit
    git fetch --all
    git reset --hard origin/master

    # 检查 README.md 是否有关键词 'backup'，或者文件为空
    if [[ ! -s README.md ]] || ! grep -q "backup" README.md; then
        echo "检测到 README.md 文件为空或没有关键词 'backup'，取消还原操作"
        exit 1
    fi

    # 检查 README.md 是否包含与当前项目相关的关键词
    if grep -q "${NAME}_[0-9-]\+.tar.gz" README.md || grep -q "${NAME}_[0-9-]\+.tar.gz.gpg" README.md; then
        echo "检测到与项目 $NAME 相关的备份文件关键词，开始还原"
    else
        echo "未检测到与项目 $NAME 相关的关键词，跳过还原"
        exit 1
    fi
    
    # 查找最新的备份文件
    if [[ "$USE_GPG" == "true" ]]; then
        RESTORE_FILE=$(ls "$NAME/" | grep -o "${NAME}_[0-9-]\+.tar.gz.gpg" | tail -n 1)
    else
        RESTORE_FILE=$(ls "$NAME/" | grep -o "${NAME}_[0-9-]\+.tar.gz" | tail -n 1)
    fi

    if [[ -z "$RESTORE_FILE" ]]; then
        echo "未找到合适的备份文件，取消还原"
        exit 1
    fi

    # 判断是否需要 GPG 解密
    if [[ "$USE_GPG" == "true" ]]; then
        echo "对备份文件进行 GPG 解密..."
        gpg --yes --batch --output "$TMP_DIR/${RESTORE_FILE%.gpg}" --decrypt "$NAME/$RESTORE_FILE"
        RESTORE_FILE="${RESTORE_FILE%.gpg}"
    fi

    
    # 下载并解压备份文件
    echo "还原备份文件: $RESTORE_FILE"
    tar -xzf "$NAME/$RESTORE_FILE" -C "$BACKUP_FILE"

    # 删除临时目录
    rm -rf "$TMP_DIR"

    # 判断是否需要重新启动项目
    if [[ "$SHOULD_STOP_PROJECT" == "true" ]]; then
        start_project
    fi

    echo "还原完成: $RESTORE_FILE"
}


# 主逻辑
case "$1" in
    backup)
        backup
        ;;
    restore)
        restore
        ;;
    *)
        echo "用法: $0 {backup|restore}"
        exit 1
        ;;
esac
