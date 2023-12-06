SHELL := /bin/bash # Use bash syntax

# Set up variables
GO111MODULE=on
IMAGE_TAG="quay.io/lgallett/s3:latest"
BUNDLE_IMAGE_TAG="quay.io/lgallett/s3-bundle:latest"
CATALOG_IMAGE_TAG="quay.io/lgallett/s3-catalog:latest"

all: bundle catalog install

bundle:
	podman build -t $(BUNDLE_IMAGE_TAG) . -f olm/bundle.Dockerfile
	podman push $(BUNDLE_IMAGE_TAG)

catalog:
	rm olm/catalog/catalog.json
	opm alpha render-template basic olm/basic.yaml -o json >> olm/catalog/catalog.json
	podman build -t $(CATALOG_IMAGE_TAG) . -f olm/olm.Dockerfile
	podman push $(CATALOG_IMAGE_TAG)

cco-setup:
	oc edit authentication cluster
	oc edit cloudcredentials cluster

patch:
	oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'

install:
	oc apply -f olm/catalogsource.yaml

cleanall: clean clean-csvs

clean:
	oc delete catalogsource/my-operator-catalog -n openshift-marketplace
	oc delete subs --all --all-namespaces
	oc delete credentialsrequests -n openshift-cloud-credential-operator --all 
	oc delete serviceaccounts -n ack-system --all

clean-csvs:
	oc delete csvs --all --all-namespaces

inspect:
	oc get pods -n openshift-marketplace
	oc get pods -n openshift-operators
