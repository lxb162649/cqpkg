%global debug_package %{nil}

Name:           cqpkg_manager
Version:        0.0.1
Release:        5
Summary:        Manage CQ system software packages.

License:        GPLv3+
URL:            https://github.com/lxb162649/cqpkg
Source0:        %{name}-%{version}.tar.gz
Patch0:         cqos-fix-clone.patch
Patch1:         cqos-fix-compile.patch
Patch2:         cqos-func-add-chinese-man-page.patch
Patch3:         cqos-func-improve-executable-files.patch

Requires:  git 
Requires:  yum-utils

%description
This project is mainly used to manage the CQ system software package.

%prep
%autosetup -n %{name}-%{version} -p1

%build

%install
make install DESTDIR=$RPM_BUILD_ROOT

%files
%{_bindir}/*
%{_mandir}/zh_CN/man1/*

%changelog
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