%global debug_package %{nil}

Name:           cqpkg
Version:        2.0.1
Release:        3
Summary:        Manage CQ system software packages.

License:        GPLv3+
URL:            https://github.com/lxb162649/cqpkg
Source0:        %{name}-%{version}.tar.gz
Patch0:         cqos-fix-install.patch
Patch1:         cqos-fix-local_repo.patch

Requires:  git 
Requires:  yum-utils
Requires:  rpm-build
Requires:  diffutils

%description
This project is mainly used to manage the CQ system software package.

%prep
%autosetup -n %{name}-%{version} -p1

%build

%install
mkdir -p %{buildroot}/%{_datadir}/%{name}
cp -r %{_builddir}/%{name}-%{version}/* %{buildroot}/%{_datadir}/%{name}

mkdir -p %{buildroot}/%{_bindir}
ln -s %{_datadir}/%{name}/bin/cqpkg %{buildroot}/usr/bin/cqpkg

mkdir -p %{buildroot}/%{_mandir}/zh_CN/man1
install -p -D -m 644 %{_builddir}/%{name}-%{version}/share/man/zh_CN/man1/* %{buildroot}/%{_mandir}/zh_CN/man1/

%files
%{_bindir}/cqpkg
%{_datadir}/%{name}/*
%{_mandir}/zh_CN/man1/*

%changelog
* Mon Aug 04 2025 lixuebing <lixuebing@cqsoftware.com.cn> - 2.0.1-3
- 修复配置本地yum源的问题

* Fri Aug 01 2025 lixuebing <lixuebing@cqsoftware.com.cn> - 2.0.1-2
- 修复安装问题

* Fri Aug 01 2025 lixuebing <lixuebing@cqsoftware.com.cn> - 2.0.1-1
- 升级版本到2.0.1，合并cqpkg_manager和manproc到cqpkg_manager

* Wed Jul 09 2025 lixuebing <lixuebing@cqsoftware.com.cn> - 2.0.0-4
- 修复 generate_metadata 函数

* Wed Jul 09 2025 lixuebing <lixuebing@cqsoftware.com.cn> - 2.0.0-3
- 修复compile

* Mon Jul 07 2025 lixuebing <lixuebing@cqsoftware.com.cn> - 2.0.0-2
- 修复生成元数据文件函数

* Tue Jun 24 2025 lixuebing <lixuebing@cqsoftware.com.cn> - 2.0.0-1
- 升级版本到2.0.0

* Tue Jun 24 2025 lixuebing <lixuebing@cqsoftware.com.cn> - 1.0.1-3
- 增加 read 命令的 -e 参数

* Tue Jun 17 2025 lixuebing <lixuebing@cqsoftware.com.cn> - 1.0.1-2
- Add cqpatch executable file
- Add cqpatch Chinese man manual

* Tue Jun 17 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 1.0.1-1
- Upgrade version to 1.0.1.

* Tue Jun 17 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-6
- Put the cq package in the rpmbuild directory in clone.

* Tue Jun 17 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-5
- Improve executable files (add color logs, optimize code structure, etc.).

* Tue Jun 17 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-4
- Add chinese man page.

* Wed Jun 11 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-3
- Added ba bp and bs parameters for compile

* Wed Jun 11 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-2
- Fixed the issue where clone pulls dragon lizards or Euler repositories that can only be placed in the rpmbuild directory

* Fri May 30 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-1
- Initial release