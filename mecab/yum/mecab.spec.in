%{?scl:%scl_package mecab}
%{!?scl:%global pkg_name %{name}}

%define		mainver		0.996
#%%define		betaver		pre3
%define		fedorarel	1

# Note:
# mecab dictionary requires mecab-devel to rebuild it,
# and mecab requires mecab dictionary

Name:		%{?scl_prefix}mecab
Version:	%{mainver}
%if %{?betaver:0}%{!?betaver:1}
Release:	%{fedorarel}%{?dist}.9
%else
Release:	0.%{fedorarel}.%{betaver}%{?dist}.11
%endif
Summary:	Yet Another Part-of-Speech and Morphological Analyzer

Group:		Applications/Text
License:	BSD or LGPLv2+ or GPL+
URL:		http://mecab.sourceforge.net/
Source0:	http://mecab.googlecode.com/files/%{pkg_name}-%{version}.tar.gz

%{?scl:BuildRequires:%scl_runtime}
%{?scl:Requires:%scl_runtime}

%description
MeCab is a open source morphological analyzer which uses 
CRF (Conditional Random Fields) as the estimation of parameters.

NOTE:
You have to install MeCab dictionary rpm to make use
of MeCab.

%package devel
Summary:	Libraries and Header files for Mecab
Group:		Development/Libraries
Requires:	%{name}%{?isa} = %{version}-%{release}
%{?scl:Requires:%scl_runtime}

%description devel
This is the development package that provides header files and libraries
for MeCab.

%prep
%setup -q -n %{pkg_name}-%{mainver}%{?betaver}


mv doc/doxygen .
find . -name \*.cpp -print0 | xargs -0 %{__chmod} 0644

# compiler flags fix
%{__sed} -i.flags \
	-e '/-O3/s|CFLAGS=\"\(.*\)\"|CFLAGS=\${CFLAGS:-\1}|' \
	-e '/-O3/s|CXXFLAGS=\"\(.*\)\"|CXXFLAGS=\${CFLAGS:-\1}|' \
	-e '/MECAB_LIBS/s|-lstdc++||' \
	configure

# multilib change
%{__sed} -i.multilib \
	-e 's|@prefix@/lib/mecab|%{_libdir}/mecab|' \
	mecab-config.in mecabrc.in

# allow to use some non-number major number in library soname
sed -i -r 's|(major=\.)(\$func_arith_result)|\1$verstring_prefix\2|' ltmain.sh

%build
%{?scl:scl enable %{scl} - << \EOF}
set -x
%configure
# remove rpath from libtool
%{__sed} -i.rpath \
	-e 's|^hardcode_libdir_flag_spec=.*|hardcode_libdir_flag_spec=""|g' \
	-e 's|^runpath_var=LD_RUN_PATH|runpath_var=DIE_RPATH_DIE|g' \
	libtool

%{?scl_prefix:export verstring_prefix="%{scl_prefix}"}
%{__make} %{?_smp_mflags}
%{?scl:EOF}

%install
%{?scl:scl enable %{scl} - << \EOF}
set -x
%{__make} install \
	DESTDIR=$RPM_BUILD_ROOT \
	INSTALL="%{__install} -c -p"

%{__rm} -f $RPM_BUILD_ROOT%{_libdir}/lib*.{a,la}
%{__rm} -f doc/Makefile*

# create directory
%{__mkdir} -p $RPM_BUILD_ROOT%{_libdir}/mecab/dic/
%{?scl:EOF}

%check
# here enable rpath
export LD_LIBRARY_PATH=$(pwd)/src/.libs
cd tests
%{__make} check || :
cd ..

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%files
%defattr(-,root,root,-)
%doc AUTHORS BSD COPYING GPL LGPL
%doc doc/ example/
%{_mandir}/man1/%{pkg_name}.1*

%config(noreplace) %verify(not md5 size mtime) %{_sysconfdir}/mecabrc
%{_bindir}/%{pkg_name}
%{_libexecdir}/%{pkg_name}/
%{_libdir}/lib%{pkg_name}.so.*
# several dictionaries can install data files
# into the following directory.
%dir %{_libdir}/%{pkg_name}/
%dir %{_libdir}/%{pkg_name}/dic/

%files devel
%doc doxygen/
%{_bindir}/%{pkg_name}-config
%{_libdir}/lib%{pkg_name}.so
%{_includedir}/%{pkg_name}.h

%changelog
* Wed Dec 13 2017 Honza Horak <hhorak@redhat.com> - 0.996-1.9
- Release bump for rebuilding on new arches
  Related: #1518842

* Tue Oct 25 2016 Jakub Dorňák <jdornak@redhat.com> - 0.996-1.8
- skip %verify of /etc/opt/rh/rh-mysql57/mecabrc
  Resolves: #1382315

* Sun Jul 17 2016 Honza Horak <hhorak@redhat.com> - 0.996-1.7
- Prefix library major number with SCL name in soname

* Fri Jul 15 2016 Honza Horak <hhorak@redhat.com> - 0.996-1.6
- Require runtime package from the scl

* Fri Jul 15 2016 Honza Horak <hhorak@redhat.com> - 0.996-1.5
- Convert to SCL package

* Thu Feb 04 2016 Fedora Release Engineering <releng@fedoraproject.org> - 0.996-1.4
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Wed Jun 17 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.996-1.3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_23_Mass_Rebuild

* Sat May 02 2015 Kalev Lember <kalevlember@gmail.com> - 0.996-1.2
- Rebuilt for GCC 5 C++11 ABI change

* Sun Aug 17 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.996-1.1
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_22_Mass_Rebuild

* Sat Jun 07 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.996-1.1
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Sat Aug 03 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.996-1
- Rebuilt for https://fedoraproject.org/wiki/Fedora_20_Mass_Rebuild

* Fri Feb 22 2013 Mamoru TASAKA <mtasaka@fedoraproject.org> - 0.996-1
- 0.996

* Sun Feb 10 2013 Mamoru TASAKA <mtasaka@fedoraproject.org> - 0.995-1
- 0.995

* Mon Aug  6 2012 Mamoru Tasaka <mtasaka@fedoraproject.org> - 0.994-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_18_Mass_Rebuild

* Mon Jul  2 2012 Mamoru Tasaka <mtasaka@fedoraproject.org> - 0.994-1
- 0.994

* Thu Mar 29 2012 Mamoru Tasaka <mtasaka@fedoraproject.org> - 0.993-1
- 0.993

* Tue Feb 28 2012 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.991-1
- Rebuilt for c++ ABI breakage

* Sun Jan 15 2012 Mamoru Tasaka <mtasaka@fedoraproject.org> - 0.991-1
- 0.991

* Mon Jan  9 2012 Mamoru Tasaka <mtasaka@fedoraproject.org> - 0.99-1
- 0.99

* Thu Jan  5 2012 Mamoru Tasaka <mtasaka@fedoraproject.org> - 0.98-2
- F-17: rebuild against gcc47

* Tue Feb 08 2011 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.98-1
- Rebuilt for https://fedoraproject.org/wiki/Fedora_15_Mass_Rebuild

* Tue Sep 29 2009 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.98-1
- 0.98

* Wed Jul 29 2009 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.98-0.5.pre3
- Enable tests on ppc{,64} again

* Sat Jul 25 2009 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.98-0.4.pre3
- Kill tests on ppc, ppc64 for now as tests hang

* Thu Jun  4 2009 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.98-0.3.pre3
- 0.98 pre3

* Thu Apr 23 2009 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.98-0.2.pre2
- 0.98 pre2

* Mon Mar  9 2009 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.98-0.1.pre1
- Update to 0.98pre1

* Tue Feb 24 2009 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.97-4
- F-11: Mass rebuild

* Sun Jun  1 2008 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.97-3
- Remove ancient || : after %%check

* Sun Feb  3 2008 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.97-1
- 0.97

* Thu Oct 25 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.96-2
- License fix

* Wed Aug 22 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.96-1.dist.2
- Mass rebuild (buildID or binutils issue)

* Fri Aug  3 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.96-1.dist.1
- License update

* Mon Jun 11 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.96-1
- 0.96 release

* Fri May  4 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.95-2.dist.2
- rebuild

* Sun Apr  1 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.95-2
- remove -lstdc++ from mecab-config (#233424)

* Sun Mar 11 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.95-1
- 0.95

* Thu Mar  8 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.95-0.1.pre1.1
- 0.95 pre1

* Tue Feb 27 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.94-0.4.pre2
- Fix libexec dir for 64bit.

* Tue Feb 27 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.94-0.3.pre2
- Package requirement deps reconstruct

* Mon Feb 26 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.94-0.2.pre2
- Remove rpath on 64bit.

* Fri Feb 23 2007 Mamoru Tasaka <mtasaka@ioa.s.u-tokyo.ac.jp> - 0.94-0.1.pre2
- Initial packaging for Fedora.

* Fri Feb 23 2007 Minokichi Sato <m-sato@rc.kyushu-u.ac.jp>
- Initial build.
