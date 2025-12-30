# OpenWrt-Docker

本项目旨在构建适用于树莓派 1~4 、适用于 armv6/armv7/armv8(aarch64)/x86_64(amd64) 平台设备的 OpenWrt 镜像 (每日更新)。

Github: <https://github.com/pityfool/OpenWrt-Docker>

DockerHub: <https://hub.docker.com/r/pityfool/openwrt>

## 支持设备及镜像版本

### OpenWrt 标准镜像

OpenWrt 标准镜像为集成常用软件包的 Docker 镜像，镜像自带软件包可满足大多数情景下的使用需求。

|  支持设备/平台  |        DockerHub        |
| :-------------: | :---------------------: |
|    树莓派 1B    |  pityfool/openwrt:rpi1  |
|    树莓派 2B    |  pityfool/openwrt:rpi2  |
| 树莓派 3B / 3B+ |  pityfool/openwrt:rpi3  |
|    树莓派 4B    |  pityfool/openwrt:rpi4  |
|      armv7      | pityfool/openwrt:armv7  |
|  arm8/aarch64   | pityfool/openwrt:armv8  |
|  x86_64/amd64   | pityfool/openwrt:x86_64 |
|    i386/386     |  pityfool/openwrt:386   |
| Linksys EA7500 v3 | pityfool/openwrt:linksys_ea7500-v3 |

### OpenWrt-Mini 镜像

OpenWrt-Mini 镜像为几乎未添加额外软件包的 Docker 镜像，你可以自行通过 opkg 安装你需要的软件包。

|  支持设备/平台  |        DockerHub        |
| :-------------: | :---------------------: |
|    树莓派 1B    |  pityfool/openwrt-mini:rpi1  |
|    树莓派 2B    |  pityfool/openwrt-mini:rpi2  |
| 树莓派 3B / 3B+ |  pityfool/openwrt-mini:rpi3  |
|    树莓派 4B    |  pityfool/openwrt-mini:rpi4  |
|      armv7      | pityfool/openwrt-mini:armv7  |
|  arm8/aarch64   | pityfool/openwrt-mini:armv8  |
|  x86_64/amd64   | pityfool/openwrt-mini:x86_64 |
|    i386/386     |  pityfool/openwrt-mini:386   |
| Linksys EA7500 v3 | pityfool/openwrt-mini:linksys_ea7500-v3 |

## 自定义配置

### 1. 目标设备配置

构建的目标设备定义在 `config/platform.config` 文件中，格式为：
`Platform_Name/Target/Subtarget/Docker_Arch/Docker_Tag/Profile`

例如：
`x86_64/x86/64/linux-amd64/amd64/generic`
`arm_cortex-a7/mediatek/mt7629/linux-arm-v7/linksys_ea7500-v3/linksys_ea7500-v3`

- `Platform_Name`: 平台名称，用于 Docker Tag 后缀（如 `pityfool/openwrt:Platform_Name`）
- `Target`: OpenWrt 目标平台
- `Subtarget`: OpenWrt 子目标
- `Docker_Arch`: Docker 架构（如 `linux-amd64` 会转换为 `linux/amd64`）
- `Docker_Tag`: 额外的 Docker Tag（可选）
- `Profile`: ImageBuilder 构建时使用的 Profile 名称（可选，若不指定则构建默认目标）

### 2. DockerHub 推送配置

如果 fork 本项目并希望推送到自己的 DockerHub，请在 GitHub 仓库的 Settings -> Secrets and variables -> Actions 中添加以下 Secrets：

- `DOCKERHUB_USERNAME`: DockerHub 用户名
- `DOCKERHUB_PWD`: DockerHub 密码或 Access Token

添加后，Workflow 会自动检测并推送到配置的 DockerHub 仓库。

## 注意事项

- 其中，树莓派 2B 镜像同时适用于 2B/3B/3B+/4B 。 
- 若拉取镜像时不加任何标签，则将使用 latest 标签拉取镜像，latest 指向的镜像与树莓派 2B 镜像实际上为同一镜像。
- 镜像中软件包的集成情况基本上与 [SuLingGG/OpenWrt-Rpi](SuLingGG/OpenWrt-Rpi) 项目中相同，但在 SuLingGG/OpenWrt-Rpi 项目的基础上，去掉了一些与无线/内核特性强相关的软件包。
- 由于 Docker 容器与宿主机共享内核，所以 Docker 容器的内核特性与宿主机当前的内核特性相同。
- 本项目固件支持 opkg 安装软件包，软件源内有 7000+ 个软件包可供选择。
- (对于高级用户) 某些软件包可能依赖一些特定的内核特性，所以我不保证 opkg 软件源中的所有软件包都可以正常使用。且因为上文所述原因，在 OpenWrt 中安装 kmod 是无效的，如果有需求，请提前在宿主机中提前载入相应的内核模块，例如:

```
modprobe ip6_udp_tunnel
modprobe ip6table_nat
modprobe pppoe
modprobe tun
modprobe udp_tunnel
modprobe xt_TPROXY
```

镜像详细使用方法请参考博客文章:

「在 Docker 中运行 OpenWrt 旁路网关」

<https://mlapp.cn/376.html>

## 鸣谢

SuLingGG/OpenWrt-Docker (本项目基于此项目):

<https://github.com/SuLingGG/OpenWrt-Docker>

ImmortalWrt Source Repository:

<https://github.com/immortalwrt/immortalwrt/>

OpenWrt Source Repository:

<https://github.com/openwrt/openwrt/>
