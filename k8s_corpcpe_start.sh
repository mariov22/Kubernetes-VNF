#!/bin/bash
  
# Requires the following variables
# SDWNS:  namespace in the cluster vim
# NETNUM: used to select external networks
# CUSTUNIP: the ip address for the customer side of the tunnel
# VNFTUNIP: the ip address for the vnf side of the tunnel
# VCPEPUBIP: the public ip address for the vcpe
# VCPEGW: the default gateway for the vcpe

set -u # to verify variables are defined
: $SDWNS
: $NETNUM
: $CUSTUNIP
: $VNFTUNIP
: $VCPEPUBIP
: $VCPEGW

export KUBECTL="microk8s kubectl"

## 0. Instalación
echo "## 0. Instalación de las vnfs"

echo "### 0.1 Limpieza (ignorar errores)"
for vnf in access cpe
do
  helm -n $SDWNS uninstall $vnf$NETNUM 
done

for i in {1..15}; do echo -n "."; sleep 1; done
echo ''

echo "### 0.2 Creación de contenedores"

chart_suffix="chart-0.1.0.tgz"
for vnf in access cpe
do
  echo '#### $vnf$NETNUM'
  helm -n $SDWNS install $vnf$NETNUM $vnf$chart_suffix
done

for i in {1..30}; do echo -n "."; sleep 1; done
echo ''

export VACC="deploy/access$NETNUM-accesschart"
export VCPE="deploy/cpe$NETNUM-cpechart"

./start_corpcpe.sh

echo "--"
echo "K8s deployments para la red $NETNUM:"
echo $VACC
echo $VCPE
