POPCORN := /home/ashwin/pcn_compiler_lkvm
X86_64_POPCORN  := $(POPCORN)/x86_64

E = @echo
Q = @

PROGRAM := lkvm
PROGRAM_ALIAS := vm

#INC     := -isystem $(X86_64_POPCORN)/include  -I /usr/include
LD      := $(POPCORN)/bin/x86_64-popcorn-linux-gnu-ld.gold


SRCS := builtin-balloon.c builtin-debug.c builtin-help.c builtin-list.c builtin-stat.c builtin-pause.c \
builtin-resume.c builtin-run.c builtin-setup.c builtin-stop.c builtin-version.c devices.c kvm-cpu_common.c 	\
disk/core.c ioeventfd.c  framebuffer.c guest_compat.c hw/rtc.c hw/serial.c  irq_common.c x86/kvm-cpu.c kvm_common.c	\
main.c mmio_common.c  pci_common.c term.c virtio/blk.c virtio/scsi.c virtio/console.c virtio/core.c virtio/net.c\
virtio/rng.c virtio/balloon.c virtio/pci.c virtio/vsock.c disk/blk.c disk/qcow.c disk/raw.c  net/uip/core.c \
net/uip/arp.c net/uip/icmp.c net/uip/ipv4.c net/uip/tcp.c net/uip/udp.c net/uip/buf.c net/uip/csum.c	\
net/uip/dhcp.c kvm-cmd.c util/init.c util/iovec.c util/rbtree.c kvm-ipc.c util/read-write.c 		\
util/parse-options.c util/threadpool.c util/rbtree-interval.c util/strbuf.c util/util.c vfio/core.c  vfio/pci.c \
hw/i8042.c virtio/9p.c builtin-sandbox.c virtio/mmio.c virtio/9p-pdu.c x86/kvm.c x86/boot.c x86/cpuid.c \
 x86/interrupt.c x86/ioport.c x86/irq.c  x86/mptable.c hw/vesa.c 

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


DEFINES += -DBUILD_ARCH='"$(ARCH)"'
DEFINES += -D_FILE_OFFSET_BITS=64
DEFINES += -DKVMTOOLS_VERSION='"$(KVMTOOLS_VERSION)"'

GUEST_INIT := guest/init

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


X86_64_INC     := -isystem $(X86_64_POPCORN)/include -I include -I x86/include -I /usr/include -I /usr/include/x86_64-linux-gnu/
X86_64_LDFLAGS := -m elf_x86_64 -L$(X86_64_POPCORN)/lib \
                  $(addprefix $(X86_64_POPCORN),$(LIBS)) \
                  --start-group --end-group


%.o:%.c
	@echo " [CC] $<  "
	$(CC) -c $(X86_64_INC) $(CFLAGS)  $(DEFINES) $(INC)   $< -o $@

#  x86/bios.obj 

#$(KVM_INCLUDE)/common-cmds.h 
all:  $(GUEST_INIT) $(KVM_INCLUDE)/common-cmds.h $(OBJS) x86/bios/bios-rom.o x86/bios.o x86/bios.obj $(PROGRAM_ALIAS)
	@echo " [LD] $@  $(ARCH)"	
#	@echo "The objects $(OBJS) "	
	@$(LD) -o lkvm  x86/bios/bios-rom.o x86/bios.o guest/guest_init.o  $(X86_64_OBJ) $(LDFLAGS) $(X86_64_LDFLAGS) -Map x86_64_map.txt

$(PROGRAM_ALIAS): #$(PROGRAM)
	$(E) "  LN      " $@
	$(Q) ln -f $(PROGRAM) $@

$(GUEST_INIT): guest/init.c
	$(E) "  LINK GUEST_INIT   " $@
	$(Q) $(CC) -static guest/init.c -o $@
	$(Q) $(LD) $(LDFLAGS) -r -b binary -o guest/guest_init.o $(GUEST_INIT)

#
# BIOS assembly weirdness
#
BIOS_CFLAGS += -m32
BIOS_CFLAGS += -march=i386
BIOS_CFLAGS += -mregparm=3
BIOS_CLAFS += $(X86_64_INC)

BIOS_CFLAGS += -fno-stack-protector

CFLAGS  += $(CPPFLAGS) $(DEFINES) $(X86_64_INC)  -O2 -fno-strict-aliasing -g

CFLAGS += -DCONFIG_GUEST_INIT

CFLAGS +=  -Wall -nostdinc -g -target x86_64 -fno-common

CFLAGS     += -O0 -Wall -nostdinc -g
x86/bios.obj: x86/bios/bios.bin x86/bios/bios-rom.h

guest/guest_pre_init.c: $(GUEST_PRE_INIT)
	$(E) "  CONVERT " $@
	$(Q) $(call binary-to-C,$<,pre_init_binary,$@)

x86/bios/bios.bin: x86/bios/bios.bin.elf
	$(E) "  OBJCOPY " $@
	$(Q) objcopy -O binary -j .text x86/bios/bios.bin.elf x86/bios/bios.bin

x86/bios/bios-rom.o: x86/bios/bios-rom.S x86/bios/bios.bin x86/bios/bios-rom.h
	$(E) "  CC      " $@
	$(Q) gcc -c $(CFLAGS) x86/bios/bios-rom.S -o x86/bios/bios-rom.o

guest/guest_init.o:
	$(E) "  CC      " $@
	$(Q) gcc -c $(CFLAGS) guest/guest_init.c -o @$

x86/bios/bios-rom.h: x86/bios/bios.bin.elf
	$(E) "  NM      " $@
	$(Q) cd x86/bios && sh gen-offsets.sh > bios-rom.h && cd ..

x86/bios/bios.bin.elf: x86/bios/entry.S x86/bios/e820.c x86/bios/int10.c x86/bios/int15.c x86/bios/rom.ld.S
	$(E) "  CC       x86/bios/memcpy.o"
	gcc -include code16gcc.h $(CFLAGS) $(BIOS_CFLAGS) -c x86/bios/memcpy.c -o x86/bios/memcpy.o
	$(E) "  CC       x86/bios/e820.o"
	gcc -include code16gcc.h $(CFLAGS) $(BIOS_CFLAGS) -c x86/bios/e820.c -o x86/bios/e820.o	
	$(E) "  CC       x86/bios/int10.o"
	gcc -include code16gcc.h $(CFLAGS) $(BIOS_CFLAGS) -c x86/bios/int10.c -o x86/bios/int10.o
	$(E) "  CC       x86/bios/int15.o"
	gcc -include code16gcc.h $(CFLAGS) $(BIOS_CFLAGS) -c x86/bios/int15.c -o x86/bios/int15.o
	$(E) "  CC       x86/bios/entry.o"
	gcc $(CFLAGS) $(BIOS_CFLAGS) -c x86/bios/entry.S -o x86/bios/entry.o
	$(E) "  LD      " $@
	ld -T x86/bios/rom.ld.S -o x86/bios/bios.bin.elf x86/bios/memcpy.o x86/bios/entry.o x86/bios/e820.o x86/bios/int10.o x86/bios/int15.o


$(KVM_INCLUDE)/common-cmds.h: util/generate-cmdlist.sh
 
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
	$(Q) rm -rf $(GUEST_INIT)
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
	$(Q) rm -f net/uip/*.o
	$(Q) rm -f x86/*.o
