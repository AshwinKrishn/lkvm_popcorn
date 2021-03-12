POPCORN := /home/ashwin/pcn_compiler_lkvm

E = @echo
Q = @

INC     := -isystem $(X86_64_POPCORN)/include 

SRCS := builtin-balloon.c builtin-debug.c builtin-help.c builtin-list.c builtin-stat.c builtin-pause.c \
builtin-resume.c builtin-run.c builtin-setup.c builtin-stop.c builtin-version.c devices.c		\
disk/core.c framebuffer.c guest_compat.c hw/rtc.c hw/serial.c ioport.c irq.c kvm-cpu.c kvm.c		\
main.c mmio.c pci.c term.c virtio/blk.c virtio/scsi.c virtio/console.c virtio/core.c virtio/net.c	\
virtio/rng.c virtio/balloon.c virtio/pci.c disk/blk.c disk/qcow.c disk/raw.c ioeventfd.c net/uip/core.c \
net/uip/arp.c net/uip/icmp.c net/uip/ipv4.c net/uip/tcp.c net/uip/udp.c net/uip/buf.c net/uip/csum.c	\
net/uip/dhcp.c kvm-cmd.c util/init.c util/iovec.c util/rbtree.c

#SRCS := builtin-balloon.c builtin-debug.c builtin-help.c builtin-list.c builtin-stat.c builtin-pause.c \
#builtin-resume.c builtin-run.c builtin-setup.c builtin-stop.c builtin-version.c devices.c		\
#core.c framebuffer.c guest_compat.c rtc.c serial.c ioport.c irq.c kvm-cpu.c kvm.c		\
#main.c mmio.c pci.c term.c blk.c scsi.c console.c core.c net.c	\
#rng.c balloon.c pci.c blk.c qcow.c raw.c ioeventfd.c net/uip/core.c \
#arp.c icmp.c ipv4.c tcp.c udp.c buf.c csum.c	\
#net/uip/dhcp.c kvm-cmd.c util/init.c util/iovec.c util/rbtree.c
OBJS = $(SRCS:.c=.o)

KVM_INCLUDE := include

ARCH ?= $(shell uname -m | sed -e s/i.86/i386/ -e s/ppc.*/powerpc/ \
          -e s/armv7.*/arm/ -e s/aarch64.*/arm64/ -e s/mips64/mips/)
ifeq ($(ARCH),i386)
        ARCH         := x86
        DEFINES      += -DCONFIG_X86_32
endif
ifeq ($(ARCH),x86_64)
        ARCH         := x86
        DEFINES      += -DCONFIG_X86_64
endif
X86_64_POPCORN  := $(POPCORN)/x86_64


DEFINES += -DBUILD_ARCH='"$(ARCH)"'
DEFINES += -D_FILE_OFFSET_BITS=64
DEFINES += -DKVMTOOLS_VERSION='"$(KVMTOOLS_VERSION)"'

VPATH :=x86:hw:virtio:disk:net:util

CC         := $(POPCORN)/bin/clang
LIBS    := /lib/crt1.o \
           /lib/libc.a \
           /lib/libmigrate.a \
           /lib/libstack-transform.a \
           /lib/libelf.a \
           /lib/libpthread.a \
           /lib/libc.a \
           /lib/libm.a

X86_64_INC     := -isystem $(X86_64_POPCORN)/include -I include -I x86/include
X86_64_LDFLAGS := -m elf_x86_64 -L$(X86_64_POPCORN)/lib \
                  $(addprefix $(X86_64_POPCORN),$(LIBS)) \
                  --start-group --end-group
X86_64_POPCORN  := $(POPCORN)/x86_64

%.o:%.c
	@echo " [CC] $<  "
	$(Q) util/generate-cmdlist.sh > $@+ && mv $@+ $@
	@$(CC) $(DEFINES) -c  $(X86_64_INC) $< -o $@

all:  $(KVM_INCLUDE)/common-cmds.h  $(OBJS)  
	

$(KVM_INCLUDE)/common-cmds.h: util/generate-cmdlist.sh command-list.txt

$(KVM_INCLUDE)/common-cmds.h: $(wildcard Documentation/kvm-*.txt)
	$(E) "  GEN     " $@
	$(Q) util/generate-cmdlist.sh > $@+ && mv $@+ $@

clean:
	$(E) "  CLEAN"
	$(Q) rm -f x86/bios/*.bin
	$(Q) rm -f x86/bios/*.elf
	$(Q) rm -f x86/bios/*.o
	$(Q) rm -f x86/bios/bios-rom.h
	$(Q) rm -f tests/boot/boot_test.iso
	$(Q) rm -rf tests/boot/rootfs/
	$(Q) rm -f cscope.*
	$(Q) rm -f tags
	$(Q) rm -f TAGS
	$(Q) rm -f $(KVM_INCLUDE)/common-cmds.h
	$(Q) rm -f KVMTOOLS-VERSION-FILE
	$(Q) rm -f *.o
