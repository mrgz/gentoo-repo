# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit user git-r3

DESCRIPTION="DataDog Agent v6"
HOMEPAGE="https://www.datadoghq.com"
SRC_URI=""

EGIT_REPO_URI="https://github.com/DataDog/datadog-agent
	https://github.com/DataDog/integrations-core
"

EGIT_COMMIT="${PV}"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""

DEPEND="dev-lang/go
	dev-python/pip
"

RDEPEND="${DEPEND}
	app-admin/sysstat
	sys-process/procps
"

_DEST=${HOME}/go/src/github.com/DataDog

pkg_setup() {
	enewgroup dd-agent
	enewuser dd-agent -1 /bin/sh /opt/datadog-agent dd-agent
}

src_compile() {
	ebegin "Building datadog-agent ${PV}"
	mkdir -p ${_DEST}
	export GOPATH=${HOME}/go
	cp -r "${WORKDIR}/${P}" "${_DEST}/${PN}"
	pip install invoke==0.22.1 --user
	pip install wheel  --user
	export PATH=$PATH:$HOME/.local/bin/:$HOME/go/bin
	cd ${_DEST}/${PN}
	invoke deps
	invoke agent.build --rebuild --build-exclude=snmp
}

src_install() {
	ebegin "Installing datadog-agent"
	newinitd "${FILESDIR}"/datadog-agent.initd datadog-agent
	newconfd "${FILESDIR}"/datadog-agent.confd datadog-agent

	keepdir /etc/datadog-agent
	keepdir /etc/datadog-agent/conf.d
	insinto /etc/datadog-agent
	newins ${_DEST}/${PN}/bin/agent/dist/datadog.yaml datadog.yaml.example

	insinto /etc/datadog-agent/conf.d
	doins -r ${_DEST}/${PN}/bin/agent/dist/conf.d/cpu.d
	doins -r ${_DEST}/${PN}/bin/agent/dist/conf.d/io.d
	doins -r ${_DEST}/${PN}/bin/agent/dist/conf.d/jmx.d
	doins -r ${_DEST}/${PN}/bin/agent/dist/conf.d/load.d
	doins -r ${_DEST}/${PN}/bin/agent/dist/conf.d/memory.d
	doins -r ${_DEST}/${PN}/bin/agent/dist/conf.d/ntp.d
	doins -r ${_DEST}/${PN}/bin/agent/dist/conf.d/uptime.d
	doins -r ${_DEST}/${PN}/bin/agent/dist/conf.d/file_handle.d

	dodir /opt/datadog-agent/bin/agent

	insinto /opt/datadog-agent/bin/agent
	doins ${_DEST}/${PN}/bin/agent/agent
	fperms 0755 /opt/datadog-agent/bin/agent/agent

	dodir /opt/datadog-agent/bin/agent/dist
	insinto /opt/datadog-agent/bin/agent/dist
	doins -r ${_DEST}/${PN}/bin/agent/dist/checks
	doins -r ${_DEST}/${PN}/bin/agent/dist/templates
	doins -r ${_DEST}/${PN}/bin/agent/dist/utils
	doins -r ${_DEST}/${PN}/bin/agent/dist/views
	doins ${_DEST}/${PN}/bin/agent/dist/config.py

	keepdir /var/log/datadog
	dodir /var/run/datadog
	fperms 0700 /var/log/datadog
	fperms 0700 /var/run/datadog

	fowners -R dd-agent:dd-agent /etc/datadog-agent
	fowners -R dd-agent:dd-agent /opt/datadog-agent
	fowners -R dd-agent:dd-agent /var/log/datadog
	fowners -R dd-agent:dd-agent /var/run/datadog
}
