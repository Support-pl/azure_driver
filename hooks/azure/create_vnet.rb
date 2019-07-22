#!/usr/bin/env ruby

# -------------------------------------------------------------------------- #
# Copyright 2018-2019, IONe Cloud Project, Support.by                        #
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
# -------------------------------------------------------------------------- #

ONE_LOCATION = ENV["ONE_LOCATION"] if !defined?(ONE_LOCATION)

if !ONE_LOCATION
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = "/etc/one/" if !defined?(ETC_LOCATION)
else
    RUBY_LIB_LOCATION = ONE_LOCATION + "/lib/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = ONE_LOCATION + "/etc/" if !defined?(ETC_LOCATION)
end

$: << RUBY_LIB_LOCATION

require 'opennebula'

network_id  = ARGV[0]

vn = OpenNebula::VirtualNetwork.new_with_id(network_id, OpenNebula::Client.new)
rc = vn.info
if OpenNebula.is_error?(rc)
    STDERR.puts rc.message
    exit 1
end

if vn['/VNET/TEMPLATE/VN_MAD'] != 'azure' then
    puts "Not Azure Network, skipping..."
    exit 0
end

# NAME="azure_test_vnet"
# VN_MAD="azure"
# BRIDGE="azure_driver"
# RESOURCE_GROUP="new_group"
# LOCATION="West Europe"
# NETWORK_TYPE="PRIVATE"|"PUBLIC"

require 'azure_driver'

rg_name = vn["/VNET/TEMPLATE/RESOURCE_GROUP"]
location = vn["/VNET/TEMPLATE/LOCATION"]
host = vn["/VNET/TEMPLATE/HOST"] || 'default'

az_drv = AzureDriver::Client.new(host)
az_drv.mk_resource_group rg_name, location

if vn["/VNET/TEMPLATE/NETWORK_TYPE"] == "PRIVATE" then
    subnet = az_drv.mk_virtual_network({
        :name => 'one-' + vn.id.to_s + '-'+ rg_name + '-private-vnet',
        :rg_name => rg_name,
        :location => location,
        :subnet => "0"
    })
    vn.add_ar(
        'AR=[' \
        '   IP="10.0.1.4",' \
        '   SIZE="251",' \
        '   TYPE="IP4" ]'
    )
    puts "Azure Private Network is now created"
elsif vn["/VNET/TEMPLATE/NETWORK_TYPE"] == "PUBLIC" then
    puts "Azure Publuc IPs Pool is now created"
else
    puts "Network type not detected, deleting..."
    vn.delete
end