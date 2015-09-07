#!/usr/bin/python
import yaml

file = '/tmp/release_2/deployment_tasks.yaml'

with open(file,'r') as f:
    tasks = yaml.load(f)

new_tasks = [{'id': 'swift-proxy',
             'type': 'group',
             'role': ['swift-proxy'],
             'tasks': ['hiera', 'globals', 'hosts', 'firewall', 'logging'],
             'required_for': ['deploy_end'],
             'requires': ['hosts'],
             'parameters': {'strategy': {'type': 'parallel'}}},
             {'id': 'primary-swift-proxy',
             'type': 'group',
             'role': ['primary-swift-proxy'],
             'tasks': ['hiera', 'globals', 'hosts', 'firewall', 'logging'],
             'required_for': ['swift-storage-deploy', 'deploy_end'],
             'requires': ['hosts'],
             'parameters': {'strategy': {'type': 'one_by_one'}}},
             {'id': 'swift-storage',
             'type': 'group',
             'role': ['swift-storage'],
             'tasks': ['hiera', 'globals', 'hosts', 'firewall', 'logging'],
             'required_for': ['deploy_end'],
             'requires': ['hosts'],
             'parameters': {'strategy': {'type': 'parallel'}}},
             {'id': 'swift-proxy-deploy',
             'type': 'puppet',
             'groups': ['primary-swift-proxy', 'swift-proxy'],
             'required_for': ['deploy_end'],
             'requires': ['hosts'],
             'parameters': {'puppet_manifest': '/etc/fuel/plugins/swift-1.0/puppet/manifests/proxy.pp',
                            'puppet_modules': '/etc/fuel/plugins/swift-1.0/puppet/modules:/etc/puppet/modules',
                            'timeout': 3600}},
             {'id': 'swift-storage-deploy',
             'type': 'puppet',
             'groups': ['swift-storage'],
             'required_for': ['deploy_end'],
             'requires': ['hosts'],
             'parameters': {'puppet_manifest': '/etc/fuel/plugins/swift-1.0/puppet/manifests/storage.pp',
                            'puppet_modules': '/etc/fuel/plugins/swift-1.0/puppet/modules:/etc/puppet/modules',
                            'timeout': 3600}},
             {'id': 'swift-controller',
             'type': 'puppet',
             'groups': ['primary-controller', 'controller'],
             'required_for': ['deploy_end'],
             'requires': ['openstack-haproxy', 'swift'],
             'parameters': {'puppet_manifest': '/etc/fuel/plugins/swift-1.0/puppet/manifests/controller.pp',
                            'puppet_modules': '/etc/fuel/plugins/swift-1.0/puppet/modules:/etc/puppet/modules',
                            'timeout': 3600}}]

for task in new_tasks:
    found_matching_id = False
    for i,task_old in enumerate(tasks):
        if task_old.get('id')==task.get('id'):
            found_matching_id = True
            tasks[i] = task
            break
    if not found_matching_id:
        tasks.append(task)

with open(file, 'w') as f:
    yaml.dump(tasks, f, default_flow_style=False)
