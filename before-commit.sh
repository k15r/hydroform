#!/usr/bin/env bash

readonly CI_FLAG=ci

RED='\033[0;31m'
GREEN='\033[0;32m'
INVERTED='\033[7m'
NC='\033[0m' # No Color

echo -e "${INVERTED}"
echo "USER: " + $USER
echo "PATH: " + $PATH
echo "GOPATH:" + $GOPATH
echo -e "${NC}"

##
# DEP ENSURE
##
dep ensure -v --vendor-only
ensureResult=$?
if [ ${ensureResult} != 0 ]; then
	echo -e "${RED}✗ dep ensure -v --vendor-only${NC}\n$ensureResult${NC}"
	exit 1
else echo -e "${GREEN}√ dep ensure -v --vendor-only${NC}"
fi


##
# DEP STATUS
##
echo "? dep status"
depResult=$(dep status -v)
if [ $? != 0 ]; then
	echo -e "${RED}✗ dep status\n$depResult${NC}"
	exit 1
else echo -e "${GREEN}√ dep status${NC}"
fi

##
# GO TEST
##
echo "? go test"
go test -count 100 -race -coverprofile=cover.out ./...
# Check if tests passed
if [[ $? != 0 ]]; then
	echo -e "${RED}✗ go test\n${NC}"
	rm cover.out
	exit 1
else 
	echo -e "Total coverage: $(go tool cover -func=cover.out | grep total | awk '{print $3}')"
	rm cover.out
	echo -e "${GREEN}√ go test${NC}"
fi

goFilesToCheck=$(find . -type f -name "*.go" | egrep -v "\/vendor\/|_*/automock/|_*/testdata/|_*export_test.go")

#
# GO FMT
#
goFmtResult=$(echo "${goFilesToCheck}" | xargs -L1 go fmt)
if [ $(echo ${#goFmtResult}) != 0 ]
	then
    	echo -e "${RED}✗ go fmt${NC}\n$goFmtResult${NC}"
    	exit 1;
	else echo -e "${GREEN}√ go fmt${NC}"
fi

##
# GO VET
##
packagesToVet=("./internal/..." "./action/..." "./types/..." "./examples/...")

for vPackage in "${packagesToVet[@]}"; do
	vetResult=$(go vet ${vPackage})
	if [ $(echo ${#vetResult}) != 0 ]; then
		echo -e "${RED}✗ go vet ${vPackage} ${NC}\n$vetResult${NC}"
		exit 1
	else echo -e "${GREEN}√ go vet ${vPackage} ${NC}"
	fi
done
