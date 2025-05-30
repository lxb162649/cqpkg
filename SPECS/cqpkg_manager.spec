%global debug_package %{nil}

Name:           cqpkg_manager
Version:        0.0.1
Release:        1
Summary:        Manage CQ system software packages.

License:        GPLv3+
URL:            https://github.com/lxb162649/cqpkg
Source0:        %{name}-%{version}.tar.gz

Requires:  git 
Requires:  yum-utils

%description
This project is mainly used to manage the CQ system software package.

%prep
%setup -q

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
* Fri May 30 2025 Xuebing Li <lixuebing@cqsoftware.com.cn> - 0.0.1-1
- Initial release