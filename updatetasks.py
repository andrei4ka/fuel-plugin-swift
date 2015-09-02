#!/usr/bin/python
import yaml

file = '/tmp/release_2/deployment_tasks.yaml'

with open(file,'r') as f:
    tasks = yaml.load(f)

new_tasks = [{'id': 'swift-proxy',
             'type': 'group',
             'role': ['swift-proxy'],
             'tasks': ['hiera', 'globals', 'hosts', 'firewall'],
             'required_for': ['deploy_end'],
             'requires': ['hosts'],
             'parameters': {'strategy': {'type': 'parallel'}}},
             {'id': 'primary-swift-proxy',
             'type': 'group',
             'role': ['primary-swift-proxy'],
             'tasks': ['hiera', 'globals', 'hosts', 'firewall'],
             'required_for': ['swift-storage-deploy', 'deploy_end'],
             'requires': ['hosts'],
             'parameters': {'strategy': {'type': 'one_by_one'}}},
             {'id': 'swift-storage',
             'type': 'group',
             'role': ['swift-storage'],
             'tasks': ['hiera', 'globals', 'hosts', 'firewall'],
             'required_for': ['deploy_end'],
             'requires': ['hosts'],
             'parameters': {'strategy': {'type': 'parallel'}}},
             {'id': 'swift-proxy-deploy',
             'type': 'puppet',
             'groups': ['primary-swift-proxy', 'swift-proxy'],
             'required_for': ['deploy_end'],
             'requires': ['deploy_start'],
             'parameters': {'puppet_manifest': '/etc/fuel/plugins/swift-1.0/puppet/manifests/proxy.pp',
                            'puppet_modules': '/etc/fuel/plugins/swift-1.0/puppet/modules:/etc/puppet/modules',
                            'timeout': '3600'}},
             {'id': 'swift-storage-deploy',
             'type': 'puppet',
             'groups': ['swift-storage'],
             'required_for': ['deploy_end'],
             'requires': ['deploy_start'],
             'parameters': {'puppet_manifest': '/etc/fuel/plugins/swift-1.0/puppet/manifests/storage.pp',
                            'puppet_modules': '/etc/fuel/plugins/swift-1.0/puppet/modules:/etc/puppet/modules',
                            'timeout': '3600'}},
             {'id': 'swift-controller',
             'type': 'puppet',
             'groups': ['primary-controller', 'controller'],
             'required_for': ['deploy_end'],
             'requires': ['openstack-haproxy'],
             'parameters': {'puppet_manifest': '/etc/fuel/plugins/swift-1.0/puppet/manifests/controller.pp',
                            'puppet_modules': '/etc/fuel/plugins/swift-1.0/puppet/modules:/etc/puppet/modules',
                            'timeout': '3600'}}]


id_dict = { d.get('id'): i for i,d in enumerate(tasks) }

for new_task in new_tasks:
    if new_task.get('id') in id_dict:
        tasks[id_dict.get(new_task.get('id'))] = new_task
    else:
        tasks.append(new_task)

with open(file, 'w') as f:
    yaml.dump(tasks, f, default_flow_style=False)
