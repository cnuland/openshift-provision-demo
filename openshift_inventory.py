#!/usr/bin/env python

import jinja2
import json
import os
import re
import six
import time
import yaml

class OpenShiftInventory:
    def __init__(self, cluster_name, config_dir='config'):
        self.config_dir = config_dir
        self.cluster_name = cluster_name
        self.load_cluster_config()

    def load_cluster_config(self):
        self.cluster_config = {}
        cluster_main = self.load_cluster_main()
        self.load_cluster_vars('default')
        self.load_cluster_vars('openshift_release', cluster_main['openshift_release'])
        self.load_cluster_vars('deployment_type', cluster_main['deployment_type'])
        self.load_cluster_vars('cloud_provider', cluster_main['cloud_provider'])
        self.load_cluster_vars('cloud_region', cluster_main['cloud_region'])
        self.load_cluster_vars('environment_level', cluster_main['environment_level'])
        if cluster_main.get('sandbox', False):
            self.load_cluster_vars('is_sandbox')
        self.load_cluster_vars('cluster', self.cluster_name)
        self.cloud_provider_class = __import__('openshift_' + cluster_main['cloud_provider'])
        self.cloud_provider = getattr(
            self.cloud_provider_class,
            self.cloud_provider_class.inventory_class_name
        )(self)

    def load_cluster_main(self):
        for file_extension in ['yaml','yml','json']:
            mainconf = '/'.join([
                self.config_dir,
                'cluster',
                self.cluster_name,
                'vars/main.' + file_extension
            ])
            try:
                return yaml.load(file(mainconf, 'r'))
            except IOError:
                pass
        raise Exception(
            "Unable to load main cluster configuration file in {}/cluster/{}/vars/".format(
                self.config_dir,
                self.cluster_name
            )
        )

    def load_cluster_vars(self, subdir, entry='.'):
        vardir = '/'.join([self.config_dir, subdir, entry, 'vars'])
        for varfile in os.listdir(vardir):
            if not re.match(r'\w.*\.(ya?ml|json)$', varfile):
                continue
            varpath = '/'.join([vardir, varfile])
            self.cluster_config.update(yaml.load(file(varpath,'r')) or {})

    def cluster_var(self, varname):
        raw_value = self.cluster_config.get(varname, None)
        if isinstance(raw_value, str):
            return self.value_expand(raw_value)
        else:
            return raw_value

    def value_expand(self, value, depth=0):
        if depth > 10:
            raise Exception("Variable expansion depth limit exceeded")
        elif isinstance(value, six.string_types) and '{{' in value:
            t = jinja2.Template(value)
            return self.value_expand(t.render(self.cluster_config), depth + 1)
        else:
            return value

    def print_host_json(self, hostname):
        host = self.cloud_provider.get_host(hostname)
        if host:
            print(json.dumps(host))
        else:
            print('{}')

    def print_host_list_json(self):
        hosts = {
            'all': {
                'vars': {}
            },
            'controller': {
                'hosts': [],
                'vars': {
                    'ansible_become': True,
                    'ansible_user': self.cluster_var('ansible_user')
                }
            },
            'OSEv3': {
                'children': ['etcd', 'nodes'],
                'hosts': [],
                'vars': {
                    'ansible_become': True,
                    'ansible_user': self.cluster_var('ansible_user')
                }
            },
            'nodes': {
                'children': ['masters'],
                'hosts': []
            },
            'masters': {
                'hosts': []
            },
            '_meta': {
                'hostvars': {}
            }
        }
 
        if self.cluster_var('openshift_provision_controller_ssh_tcp443'):
            hosts['controller']['vars']['ansible_port'] = 443

        self.cloud_provider.populate_hosts(hosts)

        # Put etcd on masters if separate etcd nodes were not indicated
        if 'etcd' not in hosts:
            hosts['etcd'] = {
                'children': ['masters']
            }

        print(json.dumps(hosts))

    def wait_for_hosts_running(self, timeout):
        self.cloud_provider.wait_for_hosts_running(timeout)

    def create_node_image(self):
        self.cloud_provider.create_node_image()

    def scaleup(self):
        self.cloud_provider.scaleup()