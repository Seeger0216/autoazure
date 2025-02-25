#/bin/bash
# Ubuntu20 桌面环境配置(arm兼容)
# 2021 flyqie

# 遇到错误马上退出,避免出现其他问题
set -e
# ...
set -x

# Xrdp PulseAudio
function install_xrdp_pa() {
	apt-get install -y git libpulse-dev autoconf m4 intltool build-essential dpkg-dev libtool libsndfile1-dev libspeexdsp-dev libudev-dev pulseaudio
	cp /etc/apt/sources.list /etc/apt/sources.list.u2ad
	sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
	apt-get update -y
	apt build-dep pulseaudio -y
	cd /tmp
	apt source pulseaudio
	pulsever=$(pulseaudio --version | awk '{print $2}')
	cd /tmp/pulseaudio-$pulsever
	# ./configure --without-caps
	./configure
	git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
	cd pulseaudio-module-xrdp
	./bootstrap
	./configure PULSE_DIR="/tmp/pulseaudio-$pulsever"
	make
	cd /tmp/pulseaudio-$pulsever/pulseaudio-module-xrdp/src/.libs
	install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so
	# systemctl restart dbus
	# systemctl restart pulseaudio
	systemctl restart xrdp
	# 解决PA无声音问题,这似乎只在Ubuntu20出现,令人绝望...
	# Issue: https://github.com/neutrinolabs/pulseaudio-module-xrdp/issues/44
	fix_pa_systemd_issue
}

# 解决PA无声音问题,这似乎只在Ubuntu20出现,令人绝望...
# Issue: https://github.com/neutrinolabs/pulseaudio-module-xrdp/issues/44
function fix_pa_systemd_issue() {
mkdir -p /home/rdpuser/.config/systemd/user/
ln -s /dev/null /home/rdpuser/.config/systemd/user/pulseaudio.service
mkdir -p /home/rdpuser/.config/autostart/
cat <<EOF | \
  sudo tee /home/rdpuser/.config/autostart/pulseaudio.desktop
[Desktop Entry]
Type=Application
Exec=pulseaudio
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=pulseaudio
Name=pulseaudio
Comment[en_US]=pulseaudio
Comment=pulseaudio
EOF
chown -R rdpuser /home/rdpuser/.config/
chmod -R 755 /home/rdpuser/.config/
}

# 安装XRDP PA
install_xrdp_pa

apt-get autoremove -y

echo "Install Done!"
