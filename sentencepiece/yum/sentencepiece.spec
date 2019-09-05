Name:		sentencepiece
Version:	0.1.83
Release:	1%{?dist}
Summary:	An unsupervised text tokenizer for Neural Network-based text generation

Group:		Applications/Text
License:	ASL 2.0
URL:		https://github.com/google/sentencepiece
Source0:	https://github.com/google/sentencepiece/releases/download/v%{version}/sentencepiece-%{version}-Source.tar.xz

BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-%(%{__id_u} -n)
BuildRequires:	cmake3
BuildRequires:	pkgconfig
BuildRequires:	gperftools-devel
Requires:	%{name}-libs = %{version}-%{release}

%description
The SentencePiece is an unsupervised text tokenizer for Neural Network-based
text generation.

%package libs
Summary:	Runtime libraries for SentencePiece
Group:		System Environment/Libraries
Requires(post):	/sbin/ldconfig
Requires(postun):	/sbin/ldconfig

%description libs
This package contains the libraries for SentencePiece

%package tools
Summary:	Tools for SentencePiece
Group:		Applications/Text
Requires:	%{name}-libs = %{version}-%{release}

%description tools
This package contains tools for manipulate models for SentencePiece

%package devel
Summary:	Libraries and header files for SentencePiece
Group:		Development/Libraries
Requires:	%{name}-libs = %{version}-%{release}

%description devel
This package contains header files to develop a software using SentencePiece

%prep
%setup -q -n %{name}-%{version}-Source

%build
%cmake3 . -DCMAKE_INSTALL_LIBDIR=%{_libdir}
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
rm -f $RPM_BUILD_ROOT%{_libdir}/*.a

%clean
rm -rf $RPM_BUILD_ROOT

%post libs -p /sbin/ldconfig

%postun libs -p /sbin/ldconfig

%files libs
%defattr(-,root,root,-)
%doc README.md LICENSE
%{_libdir}/*.so.*

%files devel
%defattr(-,root,root,-)
%{_includedir}/sentencepiece*.h
%{_libdir}/*.so
%{_libdir}/pkgconfig/sentencepiece*.pc

%files tools
%defattr(-,root,root,-)
%{_bindir}/spm*

%changelog
* Wed Sep 04 2019 Kentaro Hayashi <hayashi@clear-code.com> - 0.1.83-1
- initial packaging
