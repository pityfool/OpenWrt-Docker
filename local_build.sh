#!/bin/bash
set -e

# Fix PATH variable containing backslashes (Windows-style paths) which confuse 'find'
export PATH=$(echo "$PATH" | sed 's|\\|/|g')

# 检查是否在 Linux 环境下运行
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "Error: This script must be run in a Linux environment (e.g., WSL, Ubuntu)."
    exit 1
fi

# 帮助信息
usage() {
    echo "Usage: $0 <platform_config_line> [mini|normal]"
    echo "Example: $0 'x86_64/x86/64/linux-amd64/amd64/generic' normal"
    echo ""
    echo "Available platforms (from config/platform.config):"
    cat config/platform.config
    exit 1
}

# 检查参数
if [ -z "$1" ]; then
    usage
fi

PLATFORM_CONFIG="$1"
BUILD_TYPE="${2:-normal}" # 默认为 normal

# 解析配置
DEVICE_PLATFORM=$(echo "$PLATFORM_CONFIG" | awk -F '/' '{print $1}')
DEVICE_TARGET=$(echo "$PLATFORM_CONFIG" | awk -F '/' '{print $2}')
DEVICE_SUBTARGET=$(echo "$PLATFORM_CONFIG" | awk -F '/' '{print $3}')
DOCKER_IMAGE_ARCH=$(echo "$PLATFORM_CONFIG" | awk -F '/' '{print $4}' | sed 's/-/\//g')
DOCKER_EXTERA_TAG=$(echo "$PLATFORM_CONFIG" | awk -F '/' '{print $5}')
DEVICE_PROFILE=$(echo "$PLATFORM_CONFIG" | awk -F '/' '{print $6}')

PREFIX_URL="https://downloads.immortalwrt.org/snapshots/targets"
IB_NAME="immortalwrt-imagebuilder-$DEVICE_TARGET-$DEVICE_SUBTARGET.Linux-x86_64"
IB_FILE="$IB_NAME.tar.zst"
PROJECT_ROOT=$(pwd)

echo "=========================================="
echo "Build Configuration:"
echo "  Platform: $DEVICE_PLATFORM"
echo "  Target: $DEVICE_TARGET"
echo "  Subtarget: $DEVICE_SUBTARGET"
echo "  Profile: $DEVICE_PROFILE"
echo "  Type: $BUILD_TYPE"
echo "=========================================="

# 检查依赖
for cmd in wget tar zstd make git docker; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed."
        exit 1
    fi
done

# 下载 Image Builder
if [ ! -f "$IB_FILE" ]; then
    echo "Downloading Image Builder..."
    wget "$PREFIX_URL/$DEVICE_TARGET/$DEVICE_SUBTARGET/$IB_FILE"
else
    echo "Image Builder already downloaded."
fi

# 解压
if [ -d "$IB_NAME" ]; then
    echo "Cleaning up old Image Builder directory..."
    rm -rf "$IB_NAME"
fi
echo "Extracting Image Builder..."
tar -I zstd -xf "$IB_FILE"

# 准备构建环境
cd "$IB_NAME"
echo "Preparing build configuration..."
cp -rf "$PROJECT_ROOT/files" .
chmod +x files/etc/rc.local

# 运行预设脚本 (需要绝对路径或相对路径正确)
chmod +x "$PROJECT_ROOT/scripts/"*
"$PROJECT_ROOT/scripts/preset-terminal-tools.sh"

# 配置自定义软件源
REPO_CONF="$PROJECT_ROOT/config/repositories.conf"
if [ -f "$REPO_CONF" ]; then
    echo "Configuring custom repositories..."
    # 替换变量并写入 Image Builder
    # 注意：Image Builder 的 repositories.conf 不需要 src/gz 前缀吗？
    # 官方 Image Builder 的 repositories.conf 确实有 src/gz 前缀。
    # 我们的 config/repositories.conf 也有。
    sed "s|DEVICE_TARGET|$DEVICE_TARGET|g; s|DEVICE_SUBTARGET|$DEVICE_SUBTARGET|g; s|DEVICE_PLATFORM|$DEVICE_PLATFORM|g" "$REPO_CONF" > repositories.conf
fi

# 修改 .config
sed -i "/CONFIG_TARGET_ROOTFS_SQUASHFS/d" .config
sed -i "/CONFIG_TARGET_ROOTFS_EXT4FS/d" .config
sed -i "/CONFIG_ISO_IMAGES/d" .config
sed -i "/CONFIG_QCOW2_IMAGES/d" .config
sed -i "/CONFIG_VDI_IMAGES/d" .config
sed -i "/CONFIG_VMDK_IMAGES/d" .config
sed -i "/CONFIG_VHD_IMAGES/d" .config
sed -i "/CONFIG_TARGET_IMAGES_GZIP/d" .config

echo "# CONFIG_TARGET_ROOTFS_SQUASHFS is not set" >> .config
echo "# CONFIG_TARGET_ROOTFS_EXT4FS is not set" >> .config
echo "# CONFIG_ISO_IMAGES is not set" >> .config
echo "# CONFIG_QCOW2_IMAGES is not set" >> .config
echo "# CONFIG_VDI_IMAGES is not set" >> .config
echo "# CONFIG_VMDK_IMAGES is not set" >> .config
echo "# CONFIG_VHD_IMAGES is not set" >> .config
echo "# CONFIG_TARGET_IMAGES_GZIP is not set" >> .config
echo "CONFIG_TARGET_ROOTFS_TARGZ=y" >> .config

# 获取软件包列表
PACKAGES=""
if [ "$BUILD_TYPE" == "mini" ]; then
    PACKAGES=$(grep -v '^#' "$PROJECT_ROOT/config/mini-packages.config" | tr -s "\n" " ")
else
    PACKAGES=$(grep -v '^#' "$PROJECT_ROOT/config/normal-packages.config" | tr -s "\n" " ")
fi

# 开始构建 RootFS
echo "Building RootFS..."
if [ -n "$DEVICE_PROFILE" ]; then
    make image PROFILE="$DEVICE_PROFILE" PACKAGES="$PACKAGES" FILES="files"
else
    make image PACKAGES="$PACKAGES" FILES="files"
fi

# 复制产物
echo "Copying artifacts..."
cp bin/targets/$DEVICE_TARGET/$DEVICE_SUBTARGET/*rootfs.tar.gz "$PROJECT_ROOT/"

# 清理
cd "$PROJECT_ROOT"
# rm -rf "$IB_NAME" # 可选：保留用于调试

# 构建 Docker 镜像
echo "Building Docker Image..."

TAG_NAME="openwrt-$BUILD_TYPE:$DEVICE_PLATFORM"

docker build --platform "$DOCKER_IMAGE_ARCH" -t "$TAG_NAME" .

echo "=========================================="
echo "Build complete!"
echo "Image Tag: $TAG_NAME"
echo "Run with: docker run -d --network host --privileged $TAG_NAME"
echo "=========================================="
