#!/bin/bash

set -e

helm repo add pangeo https://pangeo-data.github.io/helm-chart/
helm repo update

helm install pangeo/pangeo --devel --version=0.1.1-86665a6 \
   --namespace=pangeo --name=pangeohub  \
   -f secret_config.yaml \
   -f jupyter_config.yaml
