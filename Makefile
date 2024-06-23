CC=gcc
DRIVERDIR?=`pwd`/driver
#KDIR?=/lib/modules/`uname -r`/build
KDIR?=/run/current-system/kernel-modules/lib/modules/6.9.3-zen1/build
#MODULEDIR?=/lib/modules/`uname -r`/kernel/drivers/usb
MODULEDIR?=/run/current-system/kernel-modules/lib/modules/6.9.3-zen1/kernel/drivers/usb/

default: build

debug: EXTRA_CFLAGS := -DDEBUG
debug: default

build:
	$(MAKE) CC=$(CC) EXTRA_CFLAGS=$(EXTRA_CFLAGS) -C $(KDIR) M=$(DRIVERDIR)

debug_install: debug install

install: default
	@mkdir -p $(MODULEDIR)
	@sudo cp -v $(DRIVERDIR)/*.ko $(MODULEDIR);
	@sudo chown -v root:root $(MODULEDIR)/*.ko;
	@sudo insmod $(MODULEDIR)/*.ko;
	sudo groupadd -f maccel;
	sudo depmod; 
	sudo chown -v :maccel /sys/module/maccel/parameters/*;
	ls -l /sys/module/maccel/parameters/*
	@echo '[Recommended] Add yourself to the "maccel" group'
	@echo '[Recommended] usermod -aG maccel $$USER'

uninstall:
	@sudo rmmod maccel
	@sudo rm -fv $(MODULEDIR)/maccel.ko

update: 
	make uninstall || true
	make install

build_cli:
	cargo build --release --manifest-path=cli/Cargo.toml
	
udev_install: build_cli
	sudo install -m 644 -v -D `pwd`/udev_rules/99-maccel.rules /usr/lib/udev/rules.d/99-maccel.rules
	sudo install -m 755 `pwd`/cli/target/release/maccel /usr/local/bin/maccel
	sudo install -m 755 -v -D `pwd`/udev_rules/maccel_bind /usr/lib/udev/maccel_bind

udev_uninstall:
	@sudo rm -f /usr/lib/udev/rules.d/99-maccel.rules /usr/lib/udev/maccel_bind
	sudo udevadm control --reload-rules
	sudo /usr/local/bin/maccel unbindall
	@sudo rm -f /usr/local/bin/maccel

udev_trigger:
	udevadm control --reload-rules
	udevadm trigger --subsystem-match=usb --subsystem-match=input --subsystem-match=hid --attr-match=bInterfaceClass=03 --attr-match=bInterfaceSubClass=01 --attr-match=bInterfaceProtocol=02

clean:
	rm -rf $(DRIVERDIR)/.*.cmd $(DRIVERDIR)/*.ko $(DRIVERDIR)/*.mod $(DRIVERDIR)/*.mod.* $(DRIVERDIR)/*.symvers $(DRIVERDIR)/*.order $(DRIVERDIR)/*.o
