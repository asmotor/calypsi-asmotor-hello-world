# Source files
ASM_SRCS = \
	hello.s

C_SRCS = \
	main.c

# Paths
VPATH = src
DEPS_DEBUG_PATH = .deps
DEPS_RELEASE_PATH = .deps-release
BUILD_DEBUG_PATH = build
BUILD_RELEASE_PATH = build-release

# Foenix support library
MODEL = --code-model=large --data-model=small
TARGET = --target=a2560k --core=68040
LINKER_RULES = a2560k.scm

# Object files
OBJS_RELEASE = $(ASM_SRCS:%.s=$(BUILD_RELEASE_PATH)/%.o) $(C_SRCS:%.c=$(BUILD_RELEASE_PATH)/%.o)
OBJS_DEBUG = $(ASM_SRCS:%.s=$(BUILD_DEBUG_PATH)/%.o) $(C_SRCS:%.c=$(BUILD_DEBUG_PATH)/%.o)

# Build rules
$(BUILD_RELEASE_PATH)/%.o: %.s $(DEPS_RELEASE_PATH)/%.d | $(DEPS_RELEASE_PATH) $(BUILD_RELEASE_PATH)
	motor68k -fe -d$(DEPS_RELEASE_PATH)/$*.d -o$@ $<

$(BUILD_RELEASE_PATH)/%.o: %.c $(DEPS_RELEASE_PATH)/%.d | $(DEPS_RELEASE_PATH) $(BUILD_RELEASE_PATH)
	@cc68k $(MODEL) $(TARGET) --debug --dependencies -MQ$@ >$(DEPS_RELEASE_PATH)/$*.d $<
	cc68k $(MODEL) $(TARGET) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

$(BUILD_DEBUG_PATH)/%.o: %.s $(DEPS_DEBUG_PATH)/%.d | $(DEPS_DEBUG_PATH) $(BUILD_DEBUG_PATH)
	motor68k -fe -d$(DEPS_DEBUG_PATH)/$*.d -o$@ $<

$(BUILD_DEBUG_PATH)/%.o: %.c $(DEPS_DEBUG_PATH)/%.d | $(DEPS_DEBUG_PATH) $(BUILD_DEBUG_PATH)
	@cc68k $(MODEL) $(TARGET) --debug --dependencies -MQ$@ >$(DEPS_DEBUG_PATH)/$*-debug.d $<
	cc68k -$(MODEL) $(TARGET) --debug --list-file=$(@:%.o=%.lst) -o $@ $<

hello.pgz:  $(OBJS_RELEASE)
	ln68k -o $@ $^ $(TARGET) $(LINKER_RULES) --output-format=pgz --list-file=$(BUILD_RELEASE_PATH)/$@.lst --cross-reference --rtattr printf=reduced --rtattr cstartup=Foenix_user

hello.elf: $(OBJS_DEBUG)
	ln68k --debug -o $@ $^ $(TARGET) $(LINKER_RULES) --list-file=$(BUILD_DEBUG_PATH)/$@.lst --cross-reference --rtattr printf=reduced --semi-hosted $(TARGET) --stack-size=2000 --sstack-size=800

hello.hex:  $(OBJS_DEBUG) $(FOENIX_LIB)
	ln68k -o $@ $^ $(TARGET) $(LINKER_RULES) --output-format=intel-hex --list-file=$(BUILD_DEBUG_PATH)/$@.lst --cross-reference --rtattr printf=reduced --rtattr cstartup=Foenix_morfe --stack-size=2000

# Clean utility
clean:
	-rm -rf $(BUILD_RELEASE_PATH) $(BUILD_DEBUG_PATH) $(DEPS_RELEASE_PATH) $(DEPS_DEBUG_PATH)
	-rm hello.elf hello.pgz hello.hex


# Make directory utility
$(DEPS_RELEASE_PATH) $(DEPS_DEBUG_PATH) $(BUILD_RELEASE_PATH) $(BUILD_DEBUG_PATH): ; @mkdir -p $@

# Dependency files
DEP_RELEASE_FILES := $(C_SRCS:%.c=$(DEPS_RELEASE_PATH)/%.d) $(ASM_SRCS:%.s=$(DEPS_RELEASE_PATH)/%.d)
DEP_DEBUG_FILES := $(C_SRCS:%.c=$(DEPS_DEBUG_PATH)/%.d) $(ASM_SRCS:%.s=$(DEPS_DEBUG_PATH)/%.d)

$(DEP_RELEASE_FILES):

$(DEP_DEBUG_FILES):

include $(wildcard $(DEP_RELEASE_FILES) $(DEP_DEBUG_FILES))
