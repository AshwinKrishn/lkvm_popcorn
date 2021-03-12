POPCORN := /home/ashwin/pcn_compiler_lkvm

E = @echo
Q = @

INC     := -isystem $(X86_64_POPCORN)/include 
LD      := $(POPCORN)/bin/x86_64-popcorn-linux-gnu-ld.gold


SRCS := builtin-balloon.c builtin-debug.c builtin-help.c builtin-list.c builtin-stat.c builtin-pause.c \
builtin-resume.c builtin-run.c builtin-setup.c builtin-stop.c builtin-version.c devices.c		\
disk/core.c framebuffer.c guest_compat.c hw/rtc.c hw/serial.c ioport.c irq.c x86/kvm-cpu.c kvm_common.c	\
main.c mmio.c pci_common.c term.c virtio/blk.c virtio/scsi.c virtio/console.c virtio/core.c virtio/net.c\
virtio/rng.c virtio/balloon.c virtio/pci.c disk/blk.c disk/qcow.c disk/raw.c ioeventfd.c net/uip/core.c \
net/uip/arp.c net/uip/icmp.c net/uip/ipv4.c net/uip/tcp.c net/uip/udp.c net/uip/buf.c net/uip/csum.c	\
net/uip/dhcp.c kvm-cmd.c util/init.c util/iovec.c util/rbtree.c kvm-ipc.c util/read-write.c 		\
util/parse-options.c util/threadpool.c util/rbtree-interval.c util/strbuf.c util/util.c hw/pci-shmem.c  \
hw/i8042.c virtio/9p.c builtin-sandbox.c virtio/mmio.c virtio/9p-pdu.c x86/kvm.c x86/boot.c x86/cpuid.c \
x86/interrupt.c x86/ioport.c x86/irq.c x86/kvm.c x86/mptable.c


#LDFLAGS := -z noexecstack -z relro --hash-style=gnu --build-id -static
LDFLAGS := -z noexecstack -z relro --hash-style=gnu --build-id -static

ifeq ($(ARCH),x86)
        DEFINES += -DCONFIG_X86
        ARCH_HAS_FRAMEBUFFER := y
endif

X86_64_OBJ         := $(SRCS:.c=.o)



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

X86_64_POPCORN  := $(POPCORN)/x86_64

X86_64_INC     := -isystem $(X86_64_POPCORN)/include -I include -I x86/include
X86_64_LDFLAGS := -m elf_x86_64 -L$(X86_64_POPCORN)/lib \
                  $(addprefix $(X86_64_POPCORN),$(LIBS)) \
                  --start-group --end-group


%.o:%.c
	@echo " [CC] $<  "
	$(Q) util/generate-cmdlist.sh > $@+ && mv $@+ $@
	@$(CC) $(DEFINES) -c  $(X86_64_INC) $< -o $@

all:  $(KVM_INCLUDE)/common-cmds.h  $(OBJS) 
	@echo " [LD] $@ (vanilla) $(ARCH)"	
	@echo "The objects $(OBJS) "	
	@$(LD) -o lkvm $(X86_64_OBJ) $(LDFLAGS) $(X86_64_LDFLAGS) -Map x86_64_map.txt

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
	$(Q) rm -f hw/*.o
	$(Q) rm -f disk/*.o
	$(Q) rm -f virtio/*.o
	$(Q) rm -f util/*.o
	$(Q) rm -f net/*.o
	$(Q) rm -f *.map
