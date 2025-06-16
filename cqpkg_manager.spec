%global debug_package %{nil}

Name:           cqpkg_manager
Version:        0.0.1
Release:        3
Summary:        Manage CQ system software packages.

License:        GPLv3+
URL:            https://github.com/lxb162649/cqpkg
Source0:        %{name}-%{version}.tar.gz
Patch0:         cqos-fix-clone.patch
Patch1:         cqos-fix-compile.patch

Requires:  git 
Requires:  yum-utils

%description
This project is mainly used to manage the CQ system software package.

%prep
%setup -q
%patch0 -p1
%patch1 -p1

%build
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make install \
    DESTDIR=$RPM_BUILD_ROOT \
    PREFIX=/usr \
    SYSCONFDIR=/etc

%files
%{_bindir}/*

%changelog
* Wed Jun 11 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-3
- Added ba bp and bs parameters for compile

* Wed Jun 11 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-2
- Fixed the issue where clone pulls dragon lizards or Euler repositories that can only be placed in the rpmbuild directory

* Fri May 30 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-1
- Initial release