fuel-plugin-swift
============

Compatible versions:

- Mirantis Fuel 7.0
- Ubuntu 14.04 server

### Purpose

Plugin configures standalone Swift cluster.

You can change the following options from Fuel UI:

- Partition/device for Swift storage.
- Create and mount loopback devices.
  - If loopback devices are going to be created/mounted you should specify size of the loopback device to create.
- Resize value. Along with the number of storage mountpoints on all Swift storage nodes determines partition power:
```
partition_power = int(log2(number_of_mountpoints*100)) + resize_value
``` 

### Building and installation

How to build plugin:

- You can build plugin using the Fuel plugin builder tool: https://pypi.python.org/pypi/fuel-plugin-builder. Install fpb Python module:

```
[local-workstation]$ pip install fpb
```

- Install system packages fpb module reiles on:
  - If you use Ubuntu, install packages `createrepo rpm dpkg-dev`
  - If you use CentOS, install packages `createrepo dpkg-devel dpkg-dev rpm rpm-build`

- Clone plugin repository and run fpb there:

```
[local-workstation]$ git clone https://github.com/andrei4ka/fuel-plugin-swift.git -b 7.0
[local-workstation]$ fpb --build fuel-plugin-swift
```

- Check if rpm file was created: 
``` 
[local-workstation]$ ls -al fuel-plugin-swift | grep rpm
-rw-rw-r--.  1 user user 656036 Jun 30 10:57 swift-1.0-1.1.0-1.noarch.rpm
```

- Upload rpm file to fuel-master node and install it. Assuming you've put rpm into /tmp directory on fuel-master:

```
[fuel-master]# cd /tmp
[fuel-master]# fuel plugins --install swift-1.0-1.1.0-1.noarch.rpm
```

- Check if Fuel sees plugin:

```
[fuel-master]# fuel plugins list
id | name              | version | package_version
---|-------------------|---------|----------------
1  | swift             | 1.1.0   | 2.0.0
```

- You can uninstall plugin using the following command:
```
[fuel-master]# fuel plugins --remove swift==1.1.0
```
Please note you can't uninstall the plugin if it is enabled for an environment. You'll have to remove an environment first, this action destroys all stored data and settings for this environment.

### Deployment process

- Create new environment, enable Swift plugin in 'Options' section of environment interface, modify settings if needed.
- Navigate to 'Nodes' section of UI, press 'Add nodes button'
- Assign controller/compute roles to the respective nodes.
- Assign swift-proxy/swift-storage roles to the swift-storage nodes (Please keep in mind: you need at least 2 swift-proxies and 3 swift-storages for HA purposes).
- Press button 'Deploy changes'

Proxy nodes will be configured using Puppet, secondary proxies along with storage nodes will fetch ring files from a primary proxy. 
HaProxy configuration for swift will be changed on controller nodes - instead of nodes with 'Controller' node assigned requests to swift-proxy will be forwarded to nodes with 'swift-proxy' roles.
Then swift-proxy will balance traffic to storage node.
