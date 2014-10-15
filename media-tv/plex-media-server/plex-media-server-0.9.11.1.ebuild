# Distributed under the terms of the GNU General Public License v2

# Submitted to Funtoo by Ghent
# + Forked from fouxlay overlay
#   + Forked from megacoffee overlay

EAPI="5"

inherit eutils user
MAGIC1="678"
MAGIC2="c48ffd2"
URI="http://downloads.plexapp.com/plex-media-server/"
DESCRIPTION="Plex Media Server is a free media library that is intended for use with a plex client available for Windows, OS X, iOS and Android or web systems. It is a standalone product which can be used in conjunction with every program, that knows the API.  For managing the library a web based interface is provided."
HOMEPAGE="http://www.plex.tv/"
KEYWORDS="-* x86 amd64"
SRC_URI="x86?	( 
			${URI}/${PV}.${MAGIC1}-${MAGIC2}/plexmediaserver_${PV}.${MAGIC1}-${MAGIC2}_i386.deb
		 )
		 amd64?	(
		 	${URI}/${PV}.${MAGIC1}-${MAGIC2}/plexmediaserver_${PV}.${MAGIC1}-${MAGIC2}_amd64.deb
		 )"

SLOT="0"
LICENSE="PMS-EULA"
IUSE=""
RDEPEND="net-dns/avahi"
DEPEND="${RDEPEND}"
#RESTRICT="fetch"  # Not sure why this was enabled in previous ebuilds, disabling for now unless something crops up
S=$WORKDIR

pkg_setup() {
	enewgroup plex
	enewuser plex -1 /bin/bash /var/lib/plexmediaserver "plex" --system
}

src_prepare() {
	mkdir data
	tar -xzf data.tar.gz -C data || die "unpack fail"
}

src_install() {
	tar -xzf data.tar.gz -C ${D} || die "main package extract fail"

	cd ${D}

	einfo "updating init script"
	# replace debian specific init scripts with gentoo specific ones
	rm ${D}/etc/init.d/plexmediaserver
	rm -r ${D}/etc/init
	newinitd "${FILESDIR}"/pms_initd_1 plex-media-server

	info "moving config files"
	# move the config to the correct place
	dodir /etc/plex 
	mv etc/default/plexmediaserver etc/plex/plexmediaserver.conf || die
	rmdir etc/default || die

	einfo "cleaning apt config entry"
	rm -r etc/apt || die

	einfo "patching startup"
	# apply patch for start_pms to use the new config file
	cd usr/sbin
	epatch "${FILESDIR}"/start_pms_1.patch || die

	cd ${D}
	# remove debian specific useless files
	rm usr/share/doc/plexmediaserver/README.Debian || die

	einfo "preparing logging targets"
	# make sure the logging directory is created
	dodir /var/log/pms
	chown plex:plex "${D}"var/log/pms || die

	einfo "prepare default library destination"
	# also make sure the default library folder is pre created with correct permissions
	dodir /var/lib/plexmediaserver
	chown plex:plex "${D}"var/lib/plexmediaserver || die
}

pkg_postinst() {
	einfo ""
	elog "Plex Media Server is now fully installed. Please check the configuration file in /etc/plex if the defaults please your needs."
	elog "To start please call '/etc/init.d/plex-media-server start'. You can manage your library afterwards by navigating to http://<ip>:32400/web/"
	einfo ""
	ewarn "Please note, that the URL to the library management has changed from http://<ip>:32400/manage to http://<ip>:32400/web!"
	ewarn "If the new management interface forces you to log into myPlex and afterwards gives you an error that you need to be a plex-pass subscriber please delete the folder WebClient.bundle inside the Plug-Ins folder found in your library!"
}

pkg_nofetch() {
	einfo "Please download, depending on your architecture,  either"
	einfo "  - plexmediaserver_${PV}.${MAGIC1}-${MAGIC2}_i386.deb"
	einfo "  - or plexmediaserver_${PV}.${MAGIC1}-${MAGIC2}_amd64.deb"
	einfo "From ${HOMEPAGE} and move it to ${DISTDIR}"
}
