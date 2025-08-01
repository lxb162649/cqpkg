# 指定使用bash作为shell
SHELL := /bin/bash

# 定义安装路径和环境变量配置文件
TARGET_DIR := $(HOME)/.cqpkg
BASHRC := $(HOME)/.bashrc
PATH_ENTRY := "export PATH=\$$PATH:$(TARGET_DIR)/bin"

# 默认目标：显示帮助信息
.DEFAULT_GOAL := help

# 安装目标：执行部署操作
install:
	@echo "开始安装..."
	# 获取当前Makefile所在目录（处理符号链接）
	$(eval SCRIPT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST)))))
	# 创建目标目录
	mkdir -p $(TARGET_DIR)
	# 复制BUILD下的文件到目标目录
	cp -rf $(SCRIPT_DIR)/../BUILD/*/* $(TARGET_DIR)/
	# 仅在环境变量未添加时写入（避免重复）
	@if ! grep -qxF $(PATH_ENTRY) $(BASHRC); then \
		echo $(PATH_ENTRY) >> $(BASHRC); \
		echo "已添加环境变量到 $(BASHRC)"; \
	else \
		echo "环境变量已存在，跳过写入"; \
	fi
	# 立即生效环境变量（使用.替代source，兼容更多shell）
	@. $(BASHRC)
	@echo "安装完成！"

# 卸载目标：清理文件和配置
uninstall:
	@echo "开始卸载..."
	# 删除目标目录
	rm -rf $(TARGET_DIR)
	# 删除环境变量配置行
	@sed -i '/^export PATH=\$$PATH:$(TARGET_DIR)\/bin$/d' $(BASHRC)
	# 立即生效环境变量（使用.替代source）
	@. $(BASHRC)
	@echo "卸载完成！"

# 帮助目标：显示使用说明
help:
	@echo "使用方法:"
	@echo "  make install   - 安装程序到 $(TARGET_DIR) 并配置环境变量"
	@echo "  make uninstall - 卸载程序并清理环境变量"
