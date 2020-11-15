#!/bin/bash
# Auto-generated by listings.scm
set -eu -o pipefail
cd "$(dirname "$0")"
curl --fail --silent --show-error --location \
	https://gitlab.com/nieper/unsyntax/-/archive/master.tar.gz |
	gunzip |
	${TAR:-tar} -tf - |
	grep -oE 'unsyntax-master.*/src/srfi/[0-9]+.s.?.?' |
	sed 's@%3a@@' |
	grep -oE '[0-9]+' |
	sort -g |
	uniq > ../data/unsyntax-head.scm
