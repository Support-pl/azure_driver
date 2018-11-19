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
# -------------------------------------------------------------------------- #

STARTUP_TIME = Time.now.to_f

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

require 'opennebula'
include OpenNebula

id = ARGV.first

vm = VirtualMachine.new_with_id id, Client.new
vm.info!

require 'azure_mgmt_compute'
require 'yaml'

begin
    size_name = vm['/VM/USER_TEMPLATE/PUBLIC_CLOUD/INSTANCE_TYPE']
    location = vm['/VM/USER_TEMPLATE/PUBLIC_CLOUD/LOCATION'].downcase.delete(' ')
    cloud_type = vm['/VM/USER_TEMPLATE/PUBLIC_CLOUD/TYPE']
rescue
    cloud_type = 'nil'
end

if cloud_type != 'AZURE' then
    puts "Not Azure(ARM) VM, skipping."
    exit 0
end

vm.hold

### Set Azure ###
@account = YAML::load(File.read(AZ_DRIVER_CONF))
_regions = @account['regions']
_az = _regions['default']
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

client = Azure::Compute::Profiles::Latest::Mgmt::Client.new(@options)

####

size = client.virtual_machine_sizes.list( location ).value.detect do |size| 
    size.name == size_name
end

capacity_template =
    "VCPU=#{size.number_of_cores}\n"\
    "MEMORY=#{size.memory_in_mb}"

vm.resize(capacity_template, false)
vm.release
puts "Work time: #{(Time.now.to_f - STARTUP_TIME).round(6).to_s} sec"