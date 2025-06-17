%global debug_package %{nil}

Name:           cqpkg_manager
Version:        1.0.1
Release:        2
Summary:        Manage CQ system software packages.

License:        GPLv3+
URL:            https://github.com/lxb162649/cqpkg
Source0:        %{name}-%{version}.tar.gz
Patch0:   		cqos-func-add-cqpkg.patch

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
make install DESTDIR=$RPM_BUILD_ROOT

%files
%{_bindir}/*
%{_mandir}/zh_CN/man1/*

%changelog
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