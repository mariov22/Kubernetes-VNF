FROM educaredes/vnf-wan

RUN apt-get clean
RUN apt-get update

COPY qos_simple_switch_13.py qos_simple_switch_13.py

RUN chmod +rwx qos_simple_switch_13.py

RUN pip install ryu

RUN sed '/OFPFlowMod(/,/)/s/)/, table_id=1)/' /usr/lib/python3/dist-packages/ryu/app/simple_switch_13.py > qos_simple_switch_13.py

#RUN ryu-manager ~/flowmanager/flowmanager.py qos_simple_switch_13.py
#RUN ryu-manager ryu.app.rest_qos ryu.app.rest_conf_switch ./qos_simple_switch_13.py



