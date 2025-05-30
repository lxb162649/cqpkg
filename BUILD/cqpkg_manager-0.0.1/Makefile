# Makefile for cqpkg_manager

# 定义变量
PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin

# 获取所有需要安装的文件（排除README.md和Makefile）
FILES := $(filter-out README.md Makefile, $(wildcard *))

# 默认目标
all:

# 安装目标
install: $(FILES)
	@echo "Installing files to $(BINDIR)..."
	@mkdir -p $(DESTDIR)$(BINDIR)
	@for file in $(FILES); do \
		echo "Installing $$file to $(DESTDIR)$(BINDIR)"; \
		install -m 0755 $$file $(DESTDIR)$(BINDIR)/$$file; \
	done

# 卸载目标
uninstall:
	@echo "Uninstalling files from $(BINDIR)..."
	@for file in $(FILES); do \
		if [ -f $(DESTDIR)$(BINDIR)/$$file ]; then \
            echo "Removing $(DESTDIR)$(BINDIR)/$$file"; \
            rm -f $(DESTDIR)$(BINDIR)/$$file; \
        fi; \
    done

# 清理目标（如果需要）
clean:
	@echo "Nothing to clean."

# 声明这些目标为伪目标
.PHONY: all install uninstall clean