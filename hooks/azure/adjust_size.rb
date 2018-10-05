#!/usr/bin/ruby

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
$: << File.dirname(__FILE__)

AZ_DRIVER_CONF = "#{ETC_LOCATION}/azure_driver.conf"

require 'opennebula'
include OpenNebula

id = ARGV.first

vm = VirtualMachine.new_with_id id, Client.new
vm.hold
vm.info!

require 'azure_mgmt_compute'
require 'yaml'


size_name = vm.to_hash['VM']['USER_TEMPLATE']['PUBLIC_CLOUD']['INSTANCE_TYPE']
location = vm.to_hash['VM']['USER_TEMPLATE']['PUBLIC_CLOUD']['LOCATION'].downcase.delete(' ')
cloud_type = vm['/VM/USER_TEMPLATE/PUBLIC_CLOUD/TYPE']

exit 0 if cloud_type != 'AZURE'

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
    "CPU=#{size.number_of_cores}\n"\
    "MEMORY=#{size.memory_in_mb}"

vm.resize(capacity_template, false)
vm.release
puts "Work time: #{(Time.now.to_f - STARTUP_TIME).round(6).to_s} sec"