<!-- omit from toc -->
RDSV/SDNV Recomendaciones sobre el trabajo final
================================================

<!-- omit from toc -->
- [1. Instalación y arranque de la máquina virtual](#1-instalación-y-arranque-de-la-máquina-virtual)
- [2. Creación de repositorios propios](#2-creación-de-repositorios-propios)
  - [2.1 Carpetas](#21-carpetas)
  - [2.2 Repositorio docker](#22-repositorio-docker)
  - [2.3 Repositorio helm](#23-repositorio-helm)
- [3. Modificación imágenes docker](#3-modificación-imágenes-docker)
- [4. Modificación de la imagen de los contenedores de los escenarios VNX](#4-modificación-de-la-imagen-de-los-contenedores-de-los-escenarios-vnx)
  - [5. Partes opcionales](#5-partes-opcionales)
    - [Repositorio Docker privado](#repositorio-docker-privado)
  - [Otras recomendaciones](#otras-recomendaciones)

# 1. Instalación y arranque de la máquina virtual

Siga las instrucciones de la [práctica 4](rdsv-p4.md) para instalar y arrancar
la máquina virtual, y pruebe a desplegar el escenario VNX y el servicio _sdedge_
para la Sede remota 1, para comprobar que la instalación funciona
correctamente. 

# 2. Creación de repositorios propios

## 2.1 Carpetas

Se recomienda trabajar en la carpeta compartida `shared`. Deberá crear dentro
de ella una carpeta `rdsv-final`, y en ella copiar las siguientes carpetas de la
práctica 4:
- `helm`
- `img`
- `json`
- `pck`
- `vnx`
- `bin`
  
Además, copie los scripts:
- `start_corpcpe.sh`
- `start_sdedge.sh`
- `start_sdwan.sh`
- `k8s_sdedge_start.sh`
- `k8s_sdwan_start.sh`
- `sdedge1.sh` y `sdedge2.sh`
- `sdwan1.sh` y `sdwan2.sh`


## 2.2 Repositorio docker

Cree una cuenta gratuita en Docker Hub https://hub.docker.com para subir sus
contenedores Docker. A continuación, acceda a las carpeta con las definiciones 
de las imagen docker y haga login para poder subir las imágenes al repositorio:

```
cd img
docker login -u <cuenta>  # pedirá password la primera vez
```

<!-- 
A continuación, para evitar que la instalación del paquete `tzdata` solicite
interactivamente información sobre la zona horaria, añada al fichero
`Dockerfile`, tras la primera línea:

```
# variables to automatically install tzdata 
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
```
-->

Después, añada un fichero README.txt que incluya los nombres de los integrantes
del grupo en cada contenedor, mediante una sentencia COPY en el Dockerfile de cada
imagen.

Una vez hecho esto, puede crear cada uno de los contenedores. Por ejemplo, para el caso de `vnf-access`:

```
cd vnf-access
docker build -t <cuenta>/vnf-access .
```

Y subirlo a Docker Hub

```
docker push <cuenta>/vnf-access
cd ..
```

## 2.3 Repositorio helm

<!--Instale la herramienta `helm`. Para ello, desde un terminal de la máquina virtual ya arrancada, ejecute:

```shell
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```
-->

Fuera de la carpeta `shared`, cree una carpeta para almacenar los ficheros del repositorio helm, que va a publicar utilizando un contenedor de docker.

```shell
mkdir $HOME/helm-files
```

Aplique los siguientes cambios en los ficheros de definición de los helm charts:

```shell
cd ~/shared/rdsv-final/helm
# cambiar en los ficheros values.yaml de cada helm chart el valor de
image:
  repository: educaredes/vnf-img --> <cuenta>/vnf-img
```

Cree en `helm-files` los *paquetes* de los helm charts y el índice del
repositorio:

```shell
# crear en helm-files los paquetes correspondientes a los helm charts
cd ~/helm-files
helm package ~/shared/rdsv-final/helm/accesschart
helm package ~/shared/rdsv-final/helm/cpechart
helm package ~/shared/rdsv-final/helm/wanchart

# crear el índice del repositorio utilizando para la creación de las URLs
# la dirección IP localhost de su máquina virtual
helm repo index --url http://127.0.0.1/ .

# comprobar que se ha creado/actualizado el fichero index.yaml
cat index.yaml
```

Arranque mediante docker un servidor web `nginx`, montando `helm-files` 
como carpeta para el contenido:

```shell
docker run --name helm-repo -p 8080:80 -v ~/helm-files:/usr/share/nginx/html:ro -d nginx
```

Es conveniente añadir la opción --restart always para que el docker se arranque automáticamente:

```shell
docker run --restart always --name helm-repo -p 8080:80 -v ~/helm-files:/usr/share/nginx/html:ro -d nginx
```

Compruebe que puede acceder al repositorio:

```shell
curl http://127.0.0.1:8080/index.yaml
```

<!--
Registre el nuevo repositorio en osm, borrando antes el repositorio previamente registrado:

```shell
# borrar el repositorio
osm repo-delete sdedge-ns-repo
# comprobar que no hay repositorios registrados 
osm repo-list
# registrar el nuevo repositorio
osm repo-add --type helm-chart --description "rdsvY repo" sdedge-ns-repo http://10.11.13.<X>
```

Finalmente, arranque desde OSM una instancia del servicio `sdedge` y mediante
kubectl acceda a los contenedores para comprobar que incluyen el software
y los ficheros instalados.
-->

A continuación, modifique el script `k8s_sdedge_start.sh` para que utilice los 
helm charts a través del servidor web. Para ello, deberá modificar la línea:

```
  helm -n $SDWNS install $vnf$NETNUM $vnf$chart_suffix
```

para que en lugar del nombre local del chart `$vnf$chart_suffix` se utilice su
url, `http://127.0.0.1:8080/$vnf$chart_suffix`. 

Finalmente, arranque la instancia del servicio `sdedge1` y mediante
kubectl o mediante el script `bin/sdw-knf-consoles` acceda a los contenedores
para comprobar que incluyen el software y los ficheros instalados.

# 3. Modificación imágenes docker

Modifique los ficheros Dockerfile de cada una de las
imágenes  para que incluya otros paquetes de ubuntu que vaya a necesitar en la
imagen. Deberá también añadir el fichero `qos_simple_switch_13.py` con la
modificación que se propone en la [práctica de
QoS](http://osrg.github.io/ryu-book/en/html/rest_qos.html)

# 4. Modificación de la imagen de los contenedores de los escenarios VNX

Para instalar nuevos paquetes en la imagen
`vnx_rootfs_lxc_ubuntu64-20.04-v025-vnxlab` utilizada por los contenedores
arrancados mediante VNX se debe:

- Parar los escenarios VNX.
- Arrancar la imagen en modo directo con:

```
vnx --modify-rootfs /usr/share/vnx/filesystems/vnx_rootfs_lxc_ubuntu64-20.04-v025-vnxlab/
```

- Hacer login con root/xxxx e instalar los paquetes deseados.
- Parar el contenedor con:

```
halt -p
```

Arrancar de nuevo los escenarios VNX y comprobar que el software instalado ya 
está disponible.

Este método se puede utilizar para instalar, por ejemplo, `iperf3`, que no está
disponible en la imagen.

## 5. Partes opcionales

### Repositorio Docker privado 

Puede encontrar información detallada sobre la configuración de MicroK8s como
repositorio privado de Docker en [este documento](repo-privado-docker.md).

## Otras recomendaciones

- En el examen oral se pedirá arrancar el escenario desde cero, por lo que es
importante que todos los pasos para cumplir los requisitos mínimos estén
automatizados mediante uno o varios scripts. Si hay partes opcionales que se
configuran de forma manual, se deberán tener documentados todos los comandos
para ejecutarlos rápidamente mediante copia-pega. 

- Se recomienda dejar la parte de configuración de la calidad de servicio para el final, una vez que el resto del escenario esté funcionando.


