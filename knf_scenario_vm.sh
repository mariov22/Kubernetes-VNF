#Comprobar si el escenario está desplegado

#microk8s kubectl get namespace $SDWNS 
#sourmicrok8s kubectl get -n $SDWNS network-attachment-definitions

#Si no está desplegado:

cd bin
./prepare-k8slab
source ~/.bashrc
echo $SDWNS

#Levantar el escenario VNX

cd ~/shared/SDNV/PRACTICA_FINAL/Kubernetes-VNF/vnx
sudo vnx -f sdedge_nfv.xml -t

#Repositorio Helm

mkdir $HOME/helm-files
cd $HOME/helm-files
helm package ~/shared/SDNV/PRACTICA_FINAL/Kubernetes-VNF/helm/accesschart
helm package ~/shared/SDNV/PRACTICA_FINAL/Kubernetes-VNF/helm/cpechart
helm package ~/shared/SDNV/PRACTICA_FINAL/Kubernetes-VNF/helm/wanchart
helm package ~/shared/SDNV/PRACTICA_FINAL/Kubernetes-VNF/helm/ctrlchart
helm repo index --url http://127.0.0.1/ .
docker run --restart always --name helm-repo -p 8080:80 -v ~/helm-files:/usr/share/nginx/html:ro -d nginx

#cd bin 
#./prepare-k8slab
#source ~/.bashrc
#echo $SDWNS
#cd ..
#cd vnx
#sudo vnx -f sdedge_nfv.xml -t