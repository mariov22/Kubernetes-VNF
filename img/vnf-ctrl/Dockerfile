FROM mariovicente/vnf-wan

RUN apt-get clean
RUN apt-get update

COPY README.txt README.txt

COPY qos_simple_switch_13.py /root/ryu/ryu/app/qos_simple_switch_13.py

RUN chmod +rwx /root/ryu/ryu/app/qos_simple_switch_13.py

RUN pip install ryu

#RUN sed '/OFPFlowMod(/,/)/s/)/, table_id=1)/' /usr/lib/python3/dist-packages/ryu/app/simple_switch_13.py > qos_simple_switch_13.py
#$WAN_EXEC /usr/local/bin/ryu-manager flowmanager/flowmanager.py ryu.app.ofctl_rest 2>&1 | tee ryu.log &

#CMD ["/usr/local/bin/ryu-manager", "flowmanager/flowmanager.py"]



