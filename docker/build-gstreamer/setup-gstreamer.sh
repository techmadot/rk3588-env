#!/bin/bash

## ディレクトリ名, URL, ハッシュを引数にとる
function cloneRepoByCommit()
{
  git init; git remote add origin $1
  git fetch --depth 1 origin $2
  git checkout FETCH_HEAD
}


cd /repos
git clone --depth=1 -b 1.21.90 https://github.com/GStreamer/gstreamer.git

## develop ブランチ. タグがないのでSHA1で固定.
## 546cb913e3feabc4a41a6220fa80d81e0dea71c2 こちらの可能性
## a308a678eb456c703f3f1e67a5f7c337ff711a69 -> [OK] こちらだと動いている気配
## 5419a46a3841c269a21afa4e7c2a0ae3f8579f12 -> [OK] 動作中 ( Dec 21, 2022)
## 272caca7c1c47e2897ca9e62ce8b122507b3bb14 -> [OK] 動作中 ( Dec 27, 2022)
## 062c17526523f22ca0ecd7c5756813e53c6b37e3 -> [NG]
## 59f7ccc6edafd6620511e0b179e0fd8f01934fe5 -> [OK]

## e7a328f49cc5d11e2570fd20971b23715852c3ab -> 古いやつ
mkdir -p /repos/rockchip_mpp; cd /repos/rockchip_mpp
cloneRepoByCommit "https://github.com/rockchip-linux/mpp.git"  "9580df24934cd3d51e19744d1f3b95f932815ae3"

## gstreamer-rockchip ブランチ. タグがないのでSHA1で固定.
mkdir -p /repos/gst-rockchipmpp; cd /repos/gst-rockchipmpp
cloneRepoByCommit "https://github.com/JeffyCN/rockchip_mirrors.git" "2ed1e68b0aa77728b1d493344d8e62a04b1b64e0"

## rockchip_mpp
cd /repos/rockchip_mpp
cd /repos/rockchip_mpp/build/linux/aarch64/
./make-Makefiles.bash
make && sudo make install

mkdir -p /opt/gstreamer/lib/aarch64-linux-gnu 
cp -a /usr/local/lib/librockchip* /opt/gstreamer/lib/aarch64-linux-gnu/

# apt install /tmp/librockchip-mpp1_1.5.0-1_arm64.deb
# apt install /tmp/librockchip-mpp-dev

## GStreamer
cd /repos/gstreamer
meson setup --prefix=/opt/gstreamer -Dgpl=enabled -Drtsp_server=disabled \
  -Dgst-plugins-ugly:x264=enabled \
  -Dgst-plugins-bad:openh264=disabled \
  -Dgst-plugins-good:rtp=disabled \
  -Dgst-plugins-good:rtpmanager=disabled \
  -Dgst-plugins-good:rtsp=disabled \
  -Dgst-plugins-good:cairo=disabled -Dgst-plugins-good:soup=disabled  \
  -Dgst-examples=disabled builddir
meson compile -C builddir
meson install -C builddir


## GST-ROCKCHIPMPP
export PKG_CONFIG_PATH=/opt/gstreamer/lib/aarch64-linux-gnu/pkgconfig
cd /repos/gst-rockchipmpp
meson setup --prefix=/opt/gstreamer -Drockchipmpp=enabled builddir
meson compile -C builddir
meson install -C builddir

export LD_LIBRARY_PATH=/opt/gstreamer/lib/aarch64-linux-gnu
/opt/gstreamer/bin/gst-inspect-1.0 | grep mpp

