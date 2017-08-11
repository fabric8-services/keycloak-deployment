### Checking logs in Kibana

Use the following query in Kibana to filter in meaningful log messages

```
kubernetes.container_name: "keycloak-server" AND NOT message: "*Allocation Failure*"
```


### Confirm from logs that keycloak clustering works 
```
:16:31,892 INFO  [org.infinispan.remoting.transport.jgroups.JGroupsTransport] (Incoming-6,kubernetes,10.1.13.206) ISPN000094: Received new cluster view for channel web: [10.1.12.52|28] (3) [10.1.12.52, 10.1.13.206, 10.1.0.105]
```

Cluster formation might take a while, ignore any errors in logs which look like

```
11:16:33,050 ERROR [org.jgroups.protocols.TCP] (TransferQueueBundler,kubernetes,10.1.13.206) JGRP000029: 10.1.13.206: failed sending message to 10.1.7.65 (73 bytes): java.net.SocketTimeoutException: connect timed out, headers: GMS: GmsHeader[VIEW_ACK], UNICAST3: DATA, seqno=144, TCP: [cluster_name=kubernetes]
```


### Handling memory issues

Maintain a good balance between the pod's memory allocation , and the Java memory allocation.
Ensure that the Java memory is slightly lesser than the pod's memory allocation to avoid the pod from crashing.

```
   strategy:
      type: Rolling
      resources:
        limits:
          memory: 2Gi
```

```
   - name: JAVA_OPTS
            value: >-
              -server -Xms256m -Xmx1434m -XX:MetaspaceSize=96M
```


### Using parameters

If there's an environment variable that wouldn't change much, as of now, it would be fair to harcode it as a parameter
Refer to discussion here : https://github.com/fabric8-services/keycloak-deployment/pull/45

```
 replicas: ${REPLICAS}
```

and then 

```
- name: REPLICAS
  value: "3"
```

### Configuration for active-active clustering


```

         - name: OPENSHIFT_KUBE_PING_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: OPENSHIFT_KUBE_PING_LABELS
            valueFrom:
              configMapKeyRef:
                name: keycloak-config
                key: openshift.kube.ping.labels
          - name: OPENSHIFT_KUBE_PING_SERVER_PORT
            valueFrom:
              configMapKeyRef:
                name: keycloak-config
                key: openshift.kube.ping.server.port
                
```

Of course you would need to specify the mode as CLUSTERED or STANDALONE

```
- name: OPERATING_MODE
  value: ${OPERATING_MODE}
```

### Testing the performance of a deployment

The performance can be tested by executing the following scripts :
https://github.com/fabric8-services/keycloak-performance-scripts





