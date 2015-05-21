
nvidia_download_dir=http://developer.download.nvidia.com/embedded/L4T/r21_Release_v3.0
nvidia_linux=Tegra124_Linux_R21.3.0_armhf.tbz2
nvidia_root=Tegra_Linux_Sample-Root-Filesystem_R21.3.0_armhf.tbz2
nvidia_linux_dir=Linux_for_Tegra
nvidia_linux_patch=Linux_for_Tegra124_R21.3.0.patch

grinch_download_dir=http://www.jarzebski.pl/files/jetsontk1/grinch-21.3.4
grinch_modules=jetson-tk1-grinch-21.3.4-modules.tar.bz2
grinch_firmware=jetson-tk1-grinch-21.3.4-firmware.tar.bz2
grinch_source=jetson-tk1-grinch-21.3.4-source.tar.bz2
grinch_modules_dir=${nvidia_linux_dir}/rootfs/lib/modules/3.10.40-grinch-21.3.4
grinch_firmware_dir=${nvidia_linux_dir}/rootfs/lib/firmware
#wget http://www.jarzebski.pl/files/jetsontk1/grinch-21.3.4/zImage

archives_dir=archives
dir_guard=@mkdir -p $(@D)

.PHONY: grinch

grinch: rootfs_grinch_modules rootfs_grinch_firmware nvidia_binaries

.PHONY: nvidia_binaries

nvidia_binaries: ${nvidia_linux_dir}/rootfs/usr/lib/arm-linux-gnueabihf/tegra/libcuda.so

${nvidia_linux_dir}/rootfs/usr/lib/arm-linux-gnueabihf/tegra/libcuda.so: rootfs rootfs_grinch_zimage
	(cd ${nvidia_linux_dir} && sudo ./apply_binaries.sh)

.PHONY: rootfs

rootfs: ${nvidia_linux_dir}/rootfs/README.txt

${nvidia_linux_dir}/rootfs/README.txt: ${nvidia_linux_dir}/patched.txt ${archives_dir}/${nvidia_root}
	sudo tar -C ${nvidia_linux_dir}/rootfs -xvpjf ${archives_dir}/${nvidia_root}
	sudo touch ${nvidia_linux_dir}/rootfs/README.txt

.PHONY: rootfs_grinch_modules rootfs_grinch_firmware rootfs_grinch_zimage

rootfs_grinch_modules: ${grinch_modules_dir}/extract_stamp

${grinch_modules_dir}/extract_stamp: nvidia_binaries ${archives_dir}/${grinch_modules}
	sudo tar -C ${nvidia_linux_dir}/rootfs/lib/modules -xvpjf ${archives_dir}/${grinch_modules}
	sudo touch ${grinch_modules_dir}/extract_stamp

rootfs_grinch_firmware: ${grinch_firmware_dir}/extract_stamp

${grinch_firmware_dir}/extract_stamp: nvidia_binaries ${archives_dir}/${grinch_firmware}
	sudo tar -C ${nvidia_linux_dir}/rootfs/lib -xvpjf ${archives_dir}/${grinch_firmware}
	sudo touch ${grinch_firmware_dir}/extract_stamp

rootfs_grinch_zimage: ${nvidia_linux_dir}/kernel/zImage

${nvidia_linux_dir}/kernel/zImage: ${archives_dir}/zImage
	sudo cp ${archives_dir}/zImage ${nvidia_linux_dir}/kernel/zImage

.PHONY: downloads_nvidia

downloads_nvidia: ${archives_dir}/${nvidia_linux} ${archives_dir}/${nvidia_root}

${archives_dir}/${nvidia_linux}:
	@mkdir -p $(@D)
	wget -cP ${archives_dir} ${nvidia_download_dir}/${nvidia_linux}

${archives_dir}/${nvidia_root}:
	@mkdir -p $(@D)
	wget -cP ${archives_dir} ${nvidia_download_dir}/${nvidia_root}

.PHONY: downloads_grinch

downloads_grinch: ${archives_dir}/zImage ${archives_dir}/${grinch_modules}\
                  ${archives_dir}/${grinch_firmware} ${archives_dir}/${grinch_source}

${archives_dir}/zImage:
	@mkdir -p $(@D)
	wget -cP ${archives_dir} ${grinch_download_dir}/zImage

${archives_dir}/${grinch_modules}:
	@mkdir -p $(@D)
	wget -cP ${archives_dir} ${grinch_download_dir}/${grinch_modules}

${archives_dir}/${grinch_firmware}:
	@mkdir -p $(@D)
	wget -cP ${archives_dir} ${grinch_download_dir}/${grinch_firmware}

${archives_dir}/${grinch_source}:
	@mkdir -p $(@D)
	wget -cP ${archives_dir} ${grinch_download_dir}/${grinch_source}

${nvidia_linux_dir}/jetson-tk1.conf: ${archives_dir}/${nvidia_linux}
	tar xvjf ${archives_dir}/${nvidia_linux}
	touch ${nvidia_linux_dir}/jetson-tk1.conf

.PHONY: patched_nvidia_linux
patched_nvidia_linux: ${nvidia_linux_dir}/patched.txt

${nvidia_linux_dir}/patched.txt: ${nvidia_linux_dir}/jetson-tk1.conf
	patch -d ${nvidia_linux_dir} -p1 -i ../${nvidia_linux_patch}
	touch ${nvidia_linux_dir}/patched.txt

.PHONY: flash

flash: grinch
	(cd Linux_for_Tegra/ && sudo ./flash.sh jetson-tk1 mmcblk0p1)

