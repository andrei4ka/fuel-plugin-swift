fuel-plugin-swift
============

Compatible versions:

- Mirantis Fuel 6.1
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
[local-workstation]$ git clone https://github.com/sheva-serg/fuel-plugin-swift
[local-workstation]$ fpb --build fuel-plugin-swift
```

- Check if rpm file was created: 
``` 
[local-workstation]$ ls -al fuel-plugin-swift | grep rpm
-rw-rw-r--.  1 user user 656036 Jun 30 10:57 swift-1.0-1.0.0-1.noarch.rpm
```

- Upload rpm file to fuel-master node and install it. Assuming you've put rpm into /tmp directory on fuel-master:

```
[fuel-master]# cd /tmp
[fuel-master]# fuel plugins --install swift-1.0-1.0.0-1.noarch.rpm
```

- Check if Fuel sees plugin:

```
[fuel-master]# fuel plugins list
id | name              | version | package_version
---|-------------------|---------|----------------
3  | swift             | 1.0.0   | 2.0.0
```

- You can uninstall plugin using the following command:
```
[fuel-master]# fuel plugins --remove swift==1.0.0
```
Please note you can't uninstall the plugin if it is enabled for an environment. You'll have to remove an environment first, this action destroys all stored data and settings for this environment.

### Deployment process

- Create new environment, enable Swift plugin in 'Options' section of environment interface, modify settings if needed.
- Navigate to 'Nodes' section of UI, press 'Add nodes button'
- Assign controller/compute roles to the respective nodes.
- Change name of the node which is going to build/host ring files to 'swift-proxy-primary-nn' where nn is an arbitrary numeric index. There should be only one node with 'swift-proxy-primary-..' name assigned.
- Change names of proxy nodes to 'swift-proxy-nn'
- Change names of storage nodes to 'swift-storage-nn'
- Assign 'base-os' role to 'swift-proxy-primary-nn', 'swift-proxy-nn', 'swift-storage-nn' nodes.
- Press button 'Deploy changes'

Proxy nodes will be configured using Puppet, secondary proxies along with storage nodes will fetch ring files from a primary proxy. HaProxy configuration for swift will be changed on controller nodes - instead of nodes with 'Controller' node assigned requests to Swift will be forwarded to nodes with 'swift-proxy-...' names.
