# Makefile for cqpkg_manager

# 定义安装路径
PREFIX ?= /usr
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man/zh_CN/man1

# 明确可执行文件列表
BIN_FILES := $(wildcard usr/bin/*)

# man手册文件列表
MAN_FILES := $(wildcard usr/share/man/zh_CN/man1/*.1)

# 安装工具（可执行文件755权限，man手册644权限）
INSTALL_BIN = install -Dm755
INSTALL_MAN = install -Dm644
RM = rm -rf
MANDOC = mandb

# 合并install目标（避免重复定义）
install: install-bin install-man

# 安装可执行文件到BIN_DIR
install-bin: $(BIN_FILES)
	@echo "安装可执行文件到 $(DESTDIR)$(BINDIR)..."
	@mkdir -p $(DESTDIR)$(BINDIR)
	@for file in $(BIN_FILES); do \
		$(INSTALL_BIN) $$file $(DESTDIR)$(BINDIR)/$$(basename $$file); \
		echo "已安装 $$(basename $$file) 到 $(DESTDIR)$(BINDIR)"; \
	done

# 安装man手册到MAN_DIR
install-man: $(MAN_FILES)
	@echo "安装man手册到 $(DESTDIR)$(MANDIR)..."
	@mkdir -p $(DESTDIR)$(MANDIR)
	@for manpage in $(MAN_FILES); do \
		$(INSTALL_MAN) $$manpage $(DESTDIR)$(MANDIR)/$$(basename $$manpage); \
		echo "已安装 $$(basename $$manpage) 到 $(DESTDIR)$(MANDIR)"; \
	done
	@if [ -z "$(DESTDIR)" ]; then $(MANDOC) -q; fi  # 非RPM模式时更新索引

# 卸载目标
uninstall:
	@echo "从 $(DESTDIR)$(BINDIR) 卸载可执行文件..."
	@for file in $(BIN_FILES); do \
		file=$(DESTDIR)$(BINDIR)/$$(basename $$file)
		if [ -f $$file ]; then \
			rm -f $$file; \
			echo "已删除 $$file"; \
		fi; \
	done
	
	@echo "从 $(DESTDIR)$(MANDIR) 卸载man手册..."
	@for manpage in $(MAN_FILES); do \
		manfile=$(DESTDIR)$(MANDIR)/$$(basename $$manpage); \
		if [ -f $$manfile ]; then \
			rm -f $$manfile; \
			echo "已删除 $$manfile"; \
		fi; \
	done
	@if [ -z "$(DESTDIR)" ]; then $(MANDOC) -q; fi
	@echo "卸载完成"

# 清理目标
clean:
	@$(RM) *~

# 声明伪目标
.PHONY: all install uninstall clean install-bin install-man
