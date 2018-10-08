#!/usr/bin/env ruby

# -------------------------------------------------------------------------- #
# Copyright 2018, IONe Cloud Project, Support.by                             #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

ONE_LOCATION = ENV["ONE_LOCATION"] if !defined?(ONE_LOCATION)

if !ONE_LOCATION
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = "/etc/one/" if !defined?(ETC_LOCATION)
else
    RUBY_LIB_LOCATION = ONE_LOCATION + "/lib/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = ONE_LOCATION + "/etc/" if !defined?(ETC_LOCATION)
end

$: << RUBY_LIB_LOCATION

AZ_DRIVER_CONF = "#{ETC_LOCATION}/azure_driver.conf"
AZ_DRIVER_DEFAULT = "#{ETC_LOCATION}/azure_driver.default"

require 'yaml'
require 'ms_rest_azure'
require 'azure_driver/azure_sdk'
require 'opennebula'
require 'VirtualMachineDriver'

module AzureDriver
    ACTION          = VirtualMachineDriver::ACTION
    POLL_ATTRIBUTE  = VirtualMachineDriver::POLL_ATTRIBUTE
    VM_STATE        = VirtualMachineDriver::VM_STATE

    class Client < Azure::Profiles::Latest::Client
        def initialize(host)
            @account = YAML::load(File.read(AZ_DRIVER_CONF))
            _regions = @account['regions']
            _az = _regions[host] || _regions['default']
            subscription_id = _az['subscription_id']
            tenant_id = _az['tenant_id']
            client_id = _az['client_id']
            client_secret = _az['client_secret']
            provider = MsRestAzure::ApplicationTokenProvider.new(
                tenant_id, #ENV['AZURE_TENANT_ID'],
                client_id, #ENV['AZURE_CLIENT_ID'],
                client_secret #ENV['AZURE_CLIENT_SECRET']
            )

            credentials = MsRest::TokenCredentials.new(provider)

            @options = {
                tenant_id: tenant_id,
                client_id: client_id,
                client_secret: client_secret,
                subscription_id: subscription_id ,
                 credentials: credentials
            }

            super(@options)
        end
        def auth host = nil
            @options
        end

        ### Virtual Machines ###

        # @param [Hash] opts
        # @option opts [String] :name - 
        # @option opts [String] :rg_name - 
        # @option opts [String] :username - 
        # @option opts [String] :passwd - 
        # @option opts [String] :hostname - 
        # @option opts [String] :plan - 
        # @option opts [String] :location - 
        # @option opts [NetworkProfile] :network_profile - 
        # @option opts [String] :name - 
        def mk_virtual_machine opts = {}
            # Include SDK modules to ease access to compute classes.
            # include Azure::Compute::Profiles::Latest::Mgmt
            # include Azure::Compute::Mgmt::V2018_04_01::Models

            # Create a model for new virtual machine
            props = compute.mgmt.model_classes.virtual_machine.new

            # windows_config = WindowsConfiguration.new
            # windows_config.provision_vmagent = true
            # windows_config.enable_automatic_updates = true

            os_profile = compute.mgmt.model_classes.osprofile.new
            os_profile.computer_name = 'azure-vm'
            os_profile.admin_username = opts[:username]
            os_profile.admin_password = opts[:passwd]
            # os_profile.windows_configuration = windows_config
            os_profile.secrets = []
            props.os_profile = os_profile

            hardware_profile = compute.mgmt.model_classes.hardware_profile.new
            hardware_profile.vm_size = opts[:plan]
            props.hardware_profile = hardware_profile

            # create_storage_profile it is hypotetical helper method which creates storage
            # profile by means of ARM Storage SDK.
            props.storage_profile = opts[:storage_profile]

            # create_storage_profile it is hypotetical helper method which creates network
            # profile my means of ARM Network SDK.
            props.network_profile = opts[:network_profile] # create_network_profile

            props.type = 'Microsoft.Compute/virtualMachines'
            props.location = opts[:location]

            compute.mgmt.virtual_machines.create_or_update(opts[:rg_name], opts[:name], props)
        end
        def get_virtual_machine deploy_id
            compute.mgmt.virtual_machines.list_all.detect do |vm|
                vm.vm_id == deploy_id
            end
        end
        def get_virtual_machine_size size_name, location
            compute.mgmt.virtual_machine_sizes.list( location ).value.detect do |size| 
                size.name == size_name
            end
        end
        def start_vm deploy_id
            vm = get_virtual_machine deploy_id
            compute.mgmt.virtual_machines.start(get_vm_rg_name(vm), vm.name)
            vm.vm_id
        end
        def stop_vm deploy_id
            vm = get_virtual_machine deploy_id
            compute.mgmt.virtual_machines.power_off(get_vm_rg_name(vm), vm.name)
            vm.vm_id
        end
        def restart_vm deploy_id
            vm = get_virtual_machine deploy_id
            compute.mgmt.virtual_machines.restart(get_vm_rg_name(vm), vm.name)
            vm.vm_id
        end
        def get_vm_deploy_id_by_one_id one_id
            compute.mgmt.virtual_machines.list_all.detect do |vm|
                vm.name.include? "one-#{one_id}-"
            end.vm_id
        end
        def get_vm_rg_name vm
            vm.id.split('/')[4]
        end

        def generate_storage_profile image
            storage_profile = compute.mgmt.model_classes.storage_profile.new

            img_ref = compute.mgmt.model_classes.image_reference.new
            img_ref.publisher = image[:publisher]
            img_ref.offer = image[:name]
            img_ref.sku = image[:version]
            img_ref.version = 'latest'
            storage_profile.image_reference = img_ref

            storage_profile
        end

        ### Resource groups  ###
        def mk_resource_group name, location

            resource_group = resources.mgmt.model_classes.resource_group.new
            resource_group.location = location

            resources.mgmt.resource_groups.create_or_update(name, resource_group)
        end

        ### Storage Accounts ###
        def mk_storage_account name, rg_name, location, sku_name, sku_kind = "Storage"
        
            params = storage.mgmt.model_classes.storage_account_create_parameters.new
            params.location = location
            sku = storage.mgmt.model_classes.sku.new
            sku.name = sku_name
            params.sku = sku
            params.kind = sku_kind || "Storage"
        
            storage.mgmt.storage_accounts.create(
                rg_name, name, params
            )
        end

        ### Virtual Networks ###
        # @param [Hash] opts
        # @option opts [String] :name - 
        # @option opts [String] :rg_name - 
        # @option opts [String] :subnet - (Optional)
        # @option opts [String] :subnet_prefix - (Optional)
        # @option opts [String] :location - 
        # @option opts [Array] :prefixes - (Optional)
        # @option opts [Array] :dns - (Optional)
        def mk_virtual_network opts = {}

            params = network.mgmt.model_classes.virtual_network.new

            address_space = network.mgmt.model_classes.address_space.new
            address_space.address_prefixes = opts[:spaces] || ['10.0.0.0/16']
            params.address_space = address_space

            dhcp_options = network.mgmt.model_classes.dhcp_options.new
            dhcp_options.dns_servers = opts[:dns] || %w(8.8.8.8 8.8.4.4)
            params.dhcp_options = dhcp_options

            sub = network.mgmt.model_classes.subnet.new
            sub.name = opts[:subnet] || 'default'
            sub.address_prefix = opts[:subnet_prefix] || '10.0.2.0/24'

            params.subnets = [sub]

            params.location = opts[:location]

            vnet = network.mgmt.virtual_networks.create_or_update(opts[:rg_name], opts[:name], params)
            vnet.subnets.first
        end
        def get_virtual_network name, rg_name

            network.mgmt.virtual_networks.get rg_name, name

        end
        def mk_network_interface name, rg_name, subnet, location

            nic = network.mgmt.model_classes.network_interface.new

            ip_conf = network.mgmt.model_classes.network_interface_ipconfiguration.new
            ip_conf.name = rg_name
            ip_conf.subnet = subnet
            nic.ip_configurations = [ip_conf]

            nic.location = location

            network.mgmt.network_interfaces.create_or_update(
                rg_name, name, nic
            )
        end

        def generate_network_profile iface
            profile = compute.mgmt.model_classes.network_profile.new

            iface_ref = compute.mgmt.model_classes.network_interface_reference.new
            iface_ref.id = iface.id

            profile.network_interfaces = [
                iface_ref
            ]
            profile
        end

        ### Monitoring ###
        def poll deploy_id
            begin
                vm = get_virtual_machine deploy_id
                rg_name = get_vm_rg_name vm
                instance = compute.mgmt.virtual_machines.get(
                    rg_name, vm.name, expand:'instanceView'
                )
        
                cpu = monitor.mgmt.metrics.list(
                    vm.id, metricnames: 'Percentage CPU', result_type: 'Data'
                ).value.first.timeseries.first.data.select { |data| data.average != nil }.last.average
                memory = 768
                nettx = monitor.mgmt.metrics.list(
                    vm.id, metricnames: 'Network In', result_type: 'Data'
                ).value.first.timeseries.first.data.select { |data| data.total != nil }.last.total
                netrx = monitor.mgmt.metrics.list(
                    vm.id, metricnames: 'Network Out', result_type: 'Data'
                ).value.first.timeseries.first.data.select { |data| data.total != nil }.last.total
                disk_rbytes = monitor.mgmt.metrics.list(
                    vm.id, metricnames: 'Disk Read Bytes', result_type: 'Data'
                ).value.first.timeseries.first.data.last.total.to_f
                disk_wbytes = monitor.mgmt.metrics.list(
                    vm.id, metricnames: 'Disk Write Bytes', result_type: 'Data'
                ).value.first.timeseries.first.data.last.total.to_f
                disk_riops = monitor.mgmt.metrics.list(
                    vm.id, metricnames: 'Disk Read Operations/Sec', result_type: 'Data'
                ).value.first.timeseries.first.data.select { |data| data.average != nil }.last.average * 60
                disk_wiops = monitor.mgmt.metrics.list(
                    vm.id, metricnames: 'Disk Write Operations/Sec', result_type: 'Data'
                ).value.first.timeseries.first.data.select { |data| data.average != nil }.last.average * 60
                
        
                info =  "#{POLL_ATTRIBUTE[:memory]}=#{memory * 1024} " \
                        "#{POLL_ATTRIBUTE[:cpu]}=#{cpu * 10} " \
                        "#{POLL_ATTRIBUTE[:nettx]}=#{nettx} " \
                        "#{POLL_ATTRIBUTE[:netrx]}=#{netrx} " \
                        "DISKRDBYTES=#{disk_rbytes} " \
                        "DISKWRBYTES=#{disk_wbytes} " \
                        "DISKRDIOPS=#{disk_riops} " \
                        "DISKWRIOPS=#{disk_wiops} " \
                        "RESOURCE_GROUP_NAME=#{rg_name} "
        
                # NETRX=126493122560 NETTX=13264445440    
        
                state = ""
                if !instance
                    state = VM_STATE[:deleted]
                else
                    state = case instance.instance_view.statuses.last.code.split('/').last
                    when "running", "starting"
                        VM_STATE[:active]
                    when "suspended", "deallocated"
                        VM_STATE[:paused]
                    else
                        VM_STATE[:unknown]
                    end
                end
        
        
                info << "#{POLL_ATTRIBUTE[:state]}=#{state}"
        
                return info, { 
                    :cpu => cpu, :memory => memory, 
                    :nettx => nettx, :netrx => netrx, 
                    :disk_rbytes => disk_rbytes, :disk_wbytes => disk_wbytes,
                    :state => state }
        
            rescue => e
            # Unknown state if exception occurs retrieving information from
            # an instance
                "#{POLL_ATTRIBUTE[:state]}=#{VM_STATE[:unknown]} "
            end
        end
    end
end
#AzureDriver.get_virtual_network 'spbywesteurope', 'test666-vnet'