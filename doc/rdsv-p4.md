<!-- omit from toc -->
Servicios SD-WAN en centrales de proximidad
===========================================

- [Resumen](#resumen)
- [Entorno](#entorno)
- [Escenario de la práctica](#escenario-de-la-práctica)
- [Referencias](#referencias)
- [Desarrollo de la práctica](#desarrollo-de-la-práctica)
  - [1. Configuración del entorno](#1-configuración-del-entorno)
    - [1.1 Instalación y arranque de la máquina virtual en el laboratorio](#11-instalación-y-arranque-de-la-máquina-virtual-en-el-laboratorio)
    - [1.1.alt Instalación y arranque de la máquina virtual en equipo propio](#11alt-instalación-y-arranque-de-la-máquina-virtual-en-equipo-propio)
    - [1.2 Preparación del entorno](#12-preparación-del-entorno)
  - [2. Arranque del escenario de red](#2-arranque-del-escenario-de-red)
  - [4. Servicio de red *corpcpe*](#4-servicio-de-red-corpcpe)
    - [4.1 (P) Imágenes vnf-access y vnf-cpe](#41-p-imágenes-vnf-access-y-vnf-cpe)
    - [4.2 Instanciación de corpcpe1](#42-instanciación-de-corpcpe1)
    - [4.3 (P) Análisis de las conexiones a redes externas y configuración](#43-p-análisis-de-las-conexiones-a-redes-externas-y-configuración)
  - [5. Servicio de red *sdedge*](#5-servicio-de-red-sdedge)
    - [5.1 Instanciación de sdedge1](#51-instanciación-de-sdedge1)
    - [5.2 Análisis de las conexiones de sdedge1 a las redes externas](#52-análisis-de-las-conexiones-de-sdedge1-a-las-redes-externas)
    - [5.3 Instanciación de sdedge2](#53-instanciación-de-sdedge2)
  - [6. (P) Configuración y aplicación de políticas de la SD-WAN](#6-p-configuración-y-aplicación-de-políticas-de-la-sd-wan)
  - [7. Finalización](#7-finalización)
  - [8. Conclusiones](#8-conclusiones)
- [Anexo I - Comandos](#anexo-i---comandos)
- [Anexo II - Figuras](#anexo-ii---figuras)

# Resumen
En esta práctica, se va a profundizar en las funciones de red virtualizadas
(_VNF_) aplicadas al caso de un servicio SD-WAN ofrecido por
un proveedor de telecomunicaciones. El escenario que se va a utilizar está
inspirado en la reconversión de las centrales de proximidad a centros de datos
que permiten, entre otras cosas, reemplazar servicios de red ofrecidos mediante
hardware específico y propietario por servicios de red definidos por software
sobre hardware de propósito general. Las funciones de red que se despliegan en
estas centrales se gestionan habitualmente mediante una plataforma de 
orquestación como OSM o XOS. 

Un caso de virtualización de servicio de red para el que ya existen numerosas
propuestas y soluciones es el del servicio vCPE (_Virtual Customer Premises
Equipment_). En nuestro caso, veremos ese servicio vCPE en el
contexto del acceso a Internet desde una red corporativa, y lo extenderemos para
llevar las funciones de un equipo SD-WAN Edge a la central de proximidad.

![Visión del servicio SD-WAN](img/summary.png "summary")

*Figura 1. Visión del servicio SD-WAN*

En concreto, partimos de un entorno SD-WAN (Figura  1.a), en el que se dispone
de equipos SD-WAN Edge sencillos "intercalados" entre el router de la LAN de una
sede remota y los equipos que dan salida hacia la red MPLS (MetroEthernet CE) y
hacia el proveedor de (Router de acceso a Internet). 

Como muestra la Figura 1.b, el objetivo será sustituir los equipos de la sede
corporativa, tanto el equipo SD-WAN Edge como el router de acceso a Internet y
el MetroEthernet CE, por un único equipo cuya gestión sea mucho más sencilla.
Este equipo es el Gateway corporativo (_Bridged Customer Gateway_ o _BCG_), que
conecta a nivel 2 el router corporativo y la central de proximidad. 

El resto de las funciones se realizan en la central de proximidad aplicando
técnicas de virtualización de funciones de red (_NFV_). Para ello, se despliega
un servicio de SD-Edge virtualizado sobre la infraestructura de virtualización
de funciones de red (_NFVI_) de la central de proximidad. Este servicio incluye
las funciones de acceso a la red MPLS, router de acceso a Internet, y funciones
específicas de SD-WAN Edge que permitan aplicar las políticas de reenvío del
tráfico corporativo bien por MPLS, bien por un túnel sobre el acceso a Internet. 

# Entorno

La Figura 2 representa el entorno en el que se va a desarrollar la práctica,
correspondiente al nivel inferior de la arquitectura NFV definida por ETSI. 
Como Virtualized Infrastructure Manager (VIM) se va a utilizar un clúster
de Kubernetes, que permite el despliegue de VNFs como contenedores,
habitualmente denominados KNFs.

![Arquitectura del entorno](img/helm-k8s-ref-arch.drawio.png "Arquitectura del
entorno")

*Figura 2. Arquitectura del entorno*

Kubernetes es una plataforma de código libre diseñada para el despliegue de
aplicaciones basadas en contenedores. Proporciona múltiples funciones de
escalabilidad, resistencia a fallos, actualizaciones y regresiones progresivas,
etc. que la hacen muy adecuada para el despliegue de VNFs. Kubernetes incluye su
propio gestor de paquetes, denominado Helm, que define la forma de crear y
operar repositorios en los que se almacenan los denominados Charts (paquetes en
terminología Helm). Básicamente, un Chart define un conjunto de recursos de
Kubernetes (contenedores, balanceadores, etc.) que se pueden posteriormente
desplegar sobre un clúster de Kubernetes. Adicionalmente, las imágenes de los
contenedores usados por Kubernetes suelen almacenarse en repositorios privados
o, más comúnmente, en el repositorio oficial de Docker denominado DockerHub.  

En la Figura 3 se aprecia con más detalle la relación entre las distintas
plataformas y repositorios involucrados en la práctica, que consistirá en el
despliegue de un servicio de red _sdedge_ compuesto por tres VNFs
interconectadas a través de una red virtual. Para desplegar dicho servicio se
proporcionan un conjunto de scripts en bash. 

![Relaciones del entorno](img/helm-docker.drawio.png "Relación entre
plataformas y repositorios")

*Figura 3. Relación entre plataformas y repositorios*

# Escenario de la práctica

La Figura 4 muestra el escenario de red que se va a desplegar en la práctica.
Está formado por dos sedes remotas, y dos centrales de proximidad. Cada central
de proximidad proporciona acceso a Internet y al servicio MetroEthernet ofrecido
sobre una red MPLS. 

![Arquitectura general](img/global-arch-tun.png "arquitectura general")
*Figura 4. Arquitectura general*

Cada sede remota X (con X = 1 ó 2) está compuesta por:
  - una red de área local con dos sistemas finales simulando un PC (hX) y un
    teléfono (tX)
  - un router (rX) 
  - un gateway corporativo (bcgX)

El router rX tiene dos interfaces hacia el gateway bcgX, una para el tráfico
corporativo y otra para el tráfico Internet.  Como es normal, cada interfaz de
rX está configurada para una subred IP distinta, al igual que sucede en el caso
de disponer de un dispositivo físico SD-Edge instalado en la sede remota. 

La red de acceso a la central de proximidad se simula mediante Open vSwitch en
modo "standalone", es decir, operando como un conmutador Ethernet clásico, con
auto aprendizaje. Cada sede remota dispone de una red de acceso distinta
AccessNetX. Además, se simulan del mismo modo:
  - las redes externas ExtNetX 
  - la red MplsWan
  - el segmento de red denominado Internet
  
Los servicios de cada central de proximidad serán desplegados mediante
Kubernetes. Por limitaciones del entorno, para la práctica se utiliza una única
instancia de _microk8s_ para el despliegue de los servicios las dos centrales de
proximidad. 

La figura muestra que las centrales de proximidad disponen de una conexión a la
red MplsWan, emulada mediante Open vSwitch. En la red MplsWan está conectado el
equipo _voip-gw_, que simula un equipo de la red corporativa accesible
directamente a través del servicio MetroEthernet, en la misma subred IP
corporativa 10.20.0.0/24 en la que se conectan los routers r1 y r2.

Cada central de proximidad tiene también una conexión a una red externa ExtNetX
dónde se ubica el router ispX que proporciona salida hacia Internet. Los
routers, por otro lado, se encuentran directamente conectados al segmento
Internet, donde también se conecta el servidor s1.

Finalmente, el escenario se completa con un acceso a la Internet "real" a través
de los routers ispX, en los que se encuentra configurado un servicio NAT que
permite realizar pruebas de conectividad con servidores bien conocidos como el
8.8.8.8.

# Referencias

* [VNX](https://web.dit.upm.es/vnxwiki/index.php/Main_Page), página sobre la
  herramienta VNX utilizada para especificar y construir el escenario de red
* [Open vSwitch](https://www.openvswitch.org), switch software para ambientes
  Linux con soporte de OpenFlow
  
# Desarrollo de la práctica

## 1. Configuración del entorno
Para realizar la práctica debe utilizar una máquina virtual distinta a la de las
prácticas anteriores, y seguir una serie de pasos  de configuración, que se
detallan a continuación. 

### 1.1 Instalación y arranque de la máquina virtual en el laboratorio
Si utiliza un PC personal propio, acceda al apartado
[1.1.alt](#11alt-instalación-y-arranque-de-la-máquina-virtual-en-equipo-propio).

Si utiliza un PC del laboratorio, siga los siguientes pasos. 

Abra un terminal, cree un directorio `shared` y descargue allí el
repositorio de la práctica: 

```
mkdir -p ~/shared
cd ~/shared
git clone https://github.com/educaredes/sdedge-ns.git
cd sdedge-ns
```

A continuación, ejecute:

```
chmod +x bin/*
bin/get-sdwlab-k8s
```

El comando `bin/get-sdwlab-k8s`:
- instala la ova que contiene la máquina virtual,
- añade el directorio compartido en la máquina virtual, en `/home/upm/shared`.
El objetivo es que esa carpeta compartida sea accesible tanto en el PC anfitrión
como en la máquina virtual _RDSV-K8S-2024-v1_. 

Arranque la máquina virtual, abra un terminal, y compruebe que puede acceder a 
la carpeta compartida `~/shared` en la que ha descargado el repositorio de la 
práctica.

### 1.1.alt Instalación y arranque de la máquina virtual en equipo propio

Si utiliza su propio PC personal, tras descargar e importar la ova, utilice la
opción de configuración de _Carpetas Compartidas_ para compartir una carpeta de
su equipo con la máquina virtual permanentemente, con punto de montaje
`/home/upm/shared`. Asegúrese además de configurar 4096 MB de memoria y 2 CPUs.

Arranque la máquina virtual, abra un terminal, y descargue en `~/shared` el
repositorio de la práctica: 

```
cd ~/shared
git clone https://github.com/educaredes/sdedge-ns.git
cd sdedge-ns
```

### 1.2 Preparación del entorno

Ejecute los comandos:

```shell
cd ~/shared/sdedge-ns/bin
./prepare-k8slab   # creates namespace and network resources
```

Cierre la ventana de terminal y vuelva a abrirla o aplique los cambios
necesarios mediante:

```shell
source ~/.bashrc
```

Compruebe que el valor de la variable de entorno SDWNS se ha definido
correctamente con:

```shell
echo $SDWNS
# debe mostrar el valor
# 'rdsv'
```

## 2. Arranque del escenario de red 

A continuación se va a arrancar el escenario de red que comprende las sedes
remotas, los routers _isp1_ e _isp2_ y los servidores _s1_ y voip-gw_. Primero
deberá comprobar que se han creado los switches `AccessNet1`, `AccessNet2`,
`ExtNet1`, `ExtNet2` y `MplsWan` tecleando en un terminal:

```shell
sudo ovs-vsctl show
```
Para conectar las KNFs con los switches, se ha utilizado
[Multus](https://github.com/k8snetworkplumbingwg/multus-cni), un plugin de tipo
_container network interface_ (CNI) para Kubernetes. 
Compruebe que están creados los correspondientes _Network
Attachment Definitions_ de _Multus_ ejecutando el comando:

```shell
kubectl get -n $SDWNS network-attachment-definitions
```

A continuación arranque el escenario con:

```shell
cd ~/shared/sdedge-ns/vnx
sudo vnx -f sdedge_nfv.xml -t
```

Por último, compruebe que hay conectividad en la sede remota 1, haciendo pruebas
en su LAN local 10.20.1.0/24 entre h1, t1 y r1. Compruebe también que hay
conectividad entre isp1, isp2 y s1 a través del segmento Internet 10.100.3.0/24.
También puede comprobar desde s1 el acceso a 8.8.8.8.

## 4. Servicio de red *corpcpe*

Comenzaremos a continuación analizando el servicio de acceso a Internet
corporativo *corpcpe*. La Figura 5 muestra los detalles de ese servicio. En
trazo punteado se han señalado algunos componentes que se encuentran
configurados, pero que no forman parte de este servicio, sino del servicio
_sdedge_ que se verá más adelante, y que será el que incluya el acceso a la red
MPLS para la comunicación entre sedes de la red corporativa. 

![Servicio de red corpcpe](img/corpcpe.png "corpcpe")

*Figura 5. Servicio de red corpcpe*

Este servicio establecerá una _SFC_ (_service function chain_ o "cadena de
funciones del servicio") para enviar el tráfico que proviene del router
corporativo hacia Internet. El tráfico llegará a través de VNF:access y pasará a
VNF:cpe, que aplicará NAT, utilizando una dirección IP pública que deberá
asignarse al servicio. Esta IP pública representa la dirección IP pública de un
router de acceso a Internet.

En el otro sentido, el servicio *corpcpe* recibirá el tráfico que proviene de
Internet con dirección destino la IP pública de VNC:cpe el NAT y lo reenviará
hacia su destino en la red corporativa, pasando por VNF:cpe y VNF:access. Será
necesario configurar en el servicio el prefijo de red utilizado por la sede
remota para que VNF:cpe realice correctamente el encaminamiento.

### 4.1 (P) Imágenes vnf-access y vnf-cpe
Las imágenes Docker que se usan por cada una de las KNFs ya se encuentran en
Docker Hub, en concreto en el repositorio
https://hub.docker.com/search?q=educaredes. Se van a analizar los ficheros
utilizados para la creación de esas imágenes: 

Desde el navegador de archivos en _~/shared/sdedge-ns_, acceda a las carpetas
_img/vnf-access_ y _vnf-cpe_. Observe que cada una de ellas contiene:

* un fichero de texto _Dockerfile_ con la configuración necesaria para crear la
  imagen del contenedor, 
* y en algún caso, ficheros adicionales que se copiarán a la imagen a través
  de la configuración del _Dockerfile_ y que serán  utilizados en la
  inicialización del contenedor.

:point_right: Identifique el nombre de la imagen estándar de partida para la
creación de vnf-access y de vnf-cpe (líneas FROM), y qué paquetes adicionales se
están instalando en cada caso. 

### 4.2 Instanciación de corpcpe1
Cree una instancia del servicio que dará acceso a Internet a la sede 1.
Para ello, utilice:

```shell
cd ~/shared/sdedge-ns
./cpe1.sh
```

Una vez arrancada la instancia del servicio puede acceder a los terminales de
las KNFs usando el comando:

```shell
cd ~/shared/sdedge-ns
bin/sdw-knf-consoles open 1
```

A continuación, realice pruebas de conectividad básicas con ping y traceroute
entre las dos KNFs para comprobar que hay conectividad, a través de las
direcciones de la interfaz `eth0`.

### 4.3 (P) Análisis de las conexiones a redes externas y configuración

A continuación se van a analizar las configuraciones iniciales del servicio
instanciado. Aunque está previsto que este tipo de configuraciones se realicen
directamente a través de la plataforma de orquestación, en este caso, se han
realizado accediendo a los contenedores mediante _kubectl_. El fichero
_cpe1.sh_, junto con los ficheros *k8s_corpcpe_start.sh* y *start_corpcpe.sh*,
contienen los comandos necesarios para realizar las configuraciones necesarias
del servicio. 

Acceda al contenido del fichero:

```shell
cat cpe1.sh
```

Acceda también al contenido de los ficheros *k8s_corpcpe_start.sh* y
*start_corpcpe.sh* que se invocan desde _cpe1.sh_.

:point_right: A partir del contenido del script _cpe1.sh_ y los demás scripts
que se llaman desde este, analice y describa resumidamente los pasos que se
están siguiendo para realizar la conexión a las redes externas y la
configuración del servicio.

Compruebe el funcionamiento del servicio, siguiendo los siguientes pasos para
probar la interconectividad entre h1 y s1:

* Desde la consola del host arranque una captura del tráfico en s1 con:

```shell
wireshark -ki s1-e1 &
```
 
* Desde h1, pruebe la conectividad con s1 mediante ping 10.100.3.3. 

:point_right: Guarde la captura con nombre _captura-h1s1_, para analizarla y
adjuntarla como resultado de la práctica.

:point_right: Analice el tráfico capturado y explique las direcciones MAC e IP
que se ven en los distintos niveles del tráfico, teniendo en cuenta que el
servicio ofrecido utiliza NAT.

A continuación, desde h1 compruebe el camino seguido por el tráfico a otros
sistemas del escenario y a Internet utilizando traceroute:

```shell
traceroute -In 192.168.255.254

traceroute -In 10.100.3.3

traceroute -In 8.8.8.8
```

:point_right: Explique los resultados de los distintos traceroute, indicando si
se corresponden con lo esperado.

A continuación desinstale las KNFs mediante el comando:
```shell
uninstall.sh
```

## 5. Servicio de red *sdedge*
El servicio de red anterior se va a extender a continuación con una nueva KNF
con el objetivo de crear un servicio _sdedge_, que está preparado para incluir
la funcionalidad SD-WAN. La Figura 6 muestra los componentes adicionales de ese
servicio.

![Servicio de red sdedge](img/sdedge.drawio.png "sdedge")

*Figura 6. Servicio de red sdedge* 

### 5.1 Instanciación de sdedge1

Cree una instancia del servicio que dará acceso a Internet a la sede 1 y acceso
a la red MPLS para la comunicación intra-corporativa, permitiendo conectar con
el equipo _voip-gw_. Para ello, utilice:

```shell
./sdedge1.sh 
```

A continuación, acceda a los terminales de las KNFs usando el comando:

```shell
bin/sdw-knf-consoles open 1
```

Y realice pruebas de conectividad básicas con ping y traceroute entre las tres
KNFs para comprobar que hay conectividad, a través de las direcciones de la
interfaz `eth0`.

### 5.2 Análisis de las conexiones de sdedge1 a las redes externas

El fichero _sdedge1_, junto con los ficheros *k8s_sdedge_start.sh* y
*start_sdedge.sh*, contiene los comandos necesarios para realizar las
configuraciones necesarias del servicio, accediendo a los contenedores mediante
_kubectl_, como se explicó anteriormente.

:point_right: Acceda al contenido de esos tres ficheros. Compare
*k8s_corpcpe_start.sh* con *k8s_sdedge_start.sh*:

```shell
diff k8s_corpcpe_start.sh k8s_sdedge_start.sh
```

Y explique las diferencias observadas. Acceda también al contenido del fichero
*start_sdedge.sh* que se invoca desde *k8s_sdedge_start.sh*.

:point_right: A partir del contenido de los distintos scripts, analice y
describa resumidamente los pasos que se están siguiendo para realizar la
conexión a las redes externas y la configuración del servicio, comparándolo con
el servicio _corpcpe_.


Compruebe el funcionamiento del servicio, verificando que sigue teniendo
acceso a Internet, y que ahora tiene acceso desde h1 y t1 al equipo voip-gw.

### 5.3 Instanciación de sdedge2
Se va a crear una nueva instancia del servicio _sdedge_ mediante un nuevo
fichero `sdedge2.sh`. Esta instancia permitirá dar acceso a la sede 2 tanto a
Internet como a la red MPLS. Para ello cree una copia del sdedge1.sh:

```shell
cp sdedge1.sh sdedge2.sh
```

A partir de la información de las direcciones IP para la Sede remota 2 (vea
Anexos), realice los cambios necesarios en el script _sdedge2_ para conectar a
las redes externas y configurar las KNFs del servicio _sdedge2_. 
 
:point_right: Deberá entregar el script _sdedge2_ como parte del resultado de la
práctica.

Acceda a los terminales de las VNFs usando el comando:

```shell
bin/sdw-knf-consoles open 2
```

Y realice pruebas de conectividad básicas con ping y traceroute entre las tres
KNFs para comprobar que hay conectividad, a través de las direcciones de la
interfaz `eth0`. Observe que las direcciones asignadas son diferentes de las
asignadas a las KNFs de _sdedge1_. 

Para probar el servicio, compruebe que ahora tiene acceso desde h2 y t2 a
Internet y al equipo voip-gw. Además, deberá realizar las siguientes pruebas de
interconectividad entre las dos sedes:

* Desde la consola de la KNF:wan del servicio sdedge1, lance una captura de
  tráfico en la interfaz net1, que da salida a la red MplsWan.

```shell
tcpdump -i net1
```

* Desde h1 lance un ping de 3 paquetes a h2:

```shell
ping -c 3 10.20.2.2
```

El tráfico del ping deberá verse en la captura, ya que inicialmente la KNF:wan
se configura para conmutar el tráfico entre KNF:access y dicha red. 

:point_right: Como resultado de este apartado, incluya el texto resultado de la
captura.

Puede dejar corriendo la captura, le servirá para comprobar qué tráfico se
conmuta a través de MplsWan en el siguiente apartado.

## 6. (P) Configuración y aplicación de políticas de la SD-WAN

A continuación, sobre los servicios de red _sdedge_ desplegados en cada una de
las sedes, se configurará el servicio SD-WAN y se aplicarán las políticas de red
correspondientes al servicio. En este caso de estudio, y tomando como referencia
la Figura 4, las políticas aplicadas permitirán cursar el tráfico
entre los hosts h1 y h2 a través del túnel VXLAN inter-sedes sobre Internet,
mientras que el tráfico entre los "teléfonos IP" t1 y t2 se continuará enviando
a través de la red MPLS. 

La Figura 7 muestra resaltados los componentes configurados para el servicio
SD-WAN.

![Servicio de red sdwan](img/sdwan.drawio.png "sdwan")

*Figura 7. Servicio de red sdedge configurado para SD-WAN*

Para realizar las configuraciones de SD-WAN sobre el servicio de red _sdedge_ se
utiliza el script _sdwan1.sh_ junto a los scripts *k8s_sdwan_start.sh* y
*start_sdwan.sh*. Acceda al contenido de esos ficheros, así como al contenido de
la carpeta _json_.

:point_right: A partir de la figura, del contenido de los scripts y de los
ficheros json, analice y describa resumidamente los pasos que se están siguiendo
para realizar la configuración del servicio y la aplicación de políticas. 

A continuación aplique los cambios sobre el servicio de la sede central 1:  

```shell
./sdwan1.sh
```

Tras realizar los cambios, obtendrá por pantalla el comando necesario para
ejecutar el navegador Firefox con acceso al controlador SDN que se ejecuta en la
KNF:wan de la sede central 1, lo que le permitirá ver las reglas aplicadas en el
conmutador _brwan_.

Aplique también los cambios sobre el servicio de la sede central 2:  

```shell
./sdwan2.sh
```

A continuación, deberá realizar las siguientes pruebas de interconectividad
entre las dos sedes:

* Desde la consola del host arranque una captura del tráfico isp1-isp2 con:

```shell
wireshark -ki isp1-e2
```
 
* Desde h1 lance un ping a h2 (dir. IP 10.20.2.2). El tráfico atraviesa isp1 e
  isp2, tal y como puede comprobar en la captura de tráfico. 

:point_right: Guarde la captura con nombre _captura-h1h2_, para analizarla y
adjuntarla como resultado de la práctica.

:point_right: Analice el tráfico capturado y explique las direcciones MAC e IP
que se ven en los distintos niveles del tráfico, teniendo en cuenta que se ha
encapsulado por un túnel VXLAN. Para que wireshark decodifique correctamente las 
cabeceras VXLAN, pinche sobre un paquete y use la opción de menú 
"Analyze->Decode As...", y luego haga doble click en la columna "Current" y
seleccione "VXLAN". 

![Wireshark decode as](img/wireshark-decode-as.png "wireshark")

*Figura 8. Selección de decodificación de paquetes en Wireshark*

* Desde t1 lance un ping a t2 (dir. IP 10.20.2.200). El tráfico no debe pasar
  por isp1-isp2, se debe encaminar por MPLS.

A continuación, desde h1 y desde t1 compruebe el camino seguido por el tráfico a
otros sistemas del escenario y a Internet utilizando traceroute.


## 7. Finalización
Para liberar los despliegues realizados en el clúster, utilice:

```shell
./uninstall.sh
```

## 8. Conclusiones
:point_right: Incluya en la entrega un apartado de conclusiones con su
valoración de la práctica, incluyendo los posibles problemas que haya encontrado
y sus sugerencias. 

# Anexo I - Comandos 

Si $PING contiene el identificador del pod, ejecuta un `<comando>` en un pod:

```
kubectl  -n $SDWNS exec -it $PING -- <comando>
```

Abre una shell en un pod:

```
kubectl  -n $SDWNS exec -it $PING -- /bin/sh
```

Arranca consolas de KNFs:

```shell
bin/sdw-knf-consoles open <ns_id>
```

# Anexo II - Figuras

![Visión del servicio SD-WAN](img/summary.png "summary")

*Figura 1. Visión del servicio SD-WAN*

---

![Arquitectura del entorno](img/helm-k8s-ref-arch.drawio.png "Arquitectura del
entorno")

*Figura 2. Arquitectura del entorno*

---

![Relaciones del entorno](img/helm-docker.drawio.png "Relación entre
plataformas y repositorios")

*Figura 3. Relación entre plataformas y repositorios*

---

![Arquitectura general](img/global-arch-tun.png "arquitectura general")
*Figura 4. Arquitectura general*

---

![Servicio de red corpcpe](img/corpcpe.png "corpcpe")

*Figura 5. Servicio de red corpcpe*

---

![Servicio de red sdedge](img/sdedge.drawio.png "sdedge")

*Figura 6. Servicio de red sdedge*

---

![Servicio de red sdwan](img/sdwan.drawio.png "sdwan")

*Figura 7. Servicio de red sdedge configurado para SD-WAN*

---

![Wireshark decode as](img/wireshark-decode-as.png "wireshark")

*Figura 8. Selección de decodificación de paquetes en Wireshark*
