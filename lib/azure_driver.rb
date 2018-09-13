#!/usr/bin/env ruby

ONE_LOCATION = ENV["ONE_LOCATION"] if !defined?(ONE_LOCATION)

if !ONE_LOCATION
    RUBY_LIB_LOCATION = "/usr/lib/one/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = "/etc/one/" if !defined?(ETC_LOCATION)
else
    RUBY_LIB_LOCATION = ONE_LOCATION + "/lib/ruby" if !defined?(RUBY_LIB_LOCATION)
    ETC_LOCATION      = ONE_LOCATION + "/etc/" if !defined?(ETC_LOCATION)
end

AZ_DRIVER_CONF = "#{ETC_LOCATION}/az_driver.conf"
AZ_DRIVER_DEFAULT = "#{ETC_LOCATION}/az_driver.default"

require 'yaml'
require 'ms_rest_azure'
# require 'azure_sdk'

module AzureDriver
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
    
    Credentials = {
        tenant_id: tenant_id,
        client_id: client_id,
        client_secret: client_secret,
        subscription_id: subscription_id,
        credentials: credentials
    }
    def self.auth
        Credentials
    end

    ### Virtual Machines ###
    def self.mk_virtual_machine opts
        
    end

    ### Resource groups  ###
    def self.mk_resource_group name, location
        require 'azure_mgmt_resources'

        include Azure::Resources::Profiles::Latest::Mgmt
        include Azure::Resources::Mgmt::V2018_02_01::Models

        resource_group = ResourceGroup.new()
        resource_group.location = location

        Client.new( auth ).resource_groups.create_or_update(name, resource_group)
    end

    ### Storage Accounts ###
    def self.mk_storage_account name, rg_name, location, sku_name  
        require 'azure_mgmt_storage'      
        
        include Azure::Storage::Profiles::Latest::Mgmt
        include Azure::Storage::Mgmt::V2018_02_01::Models
    
        params = StorageAccountCreateParameters.new
        params.location = location
        sku = Sku.new
        sku.name = sku_name
        params.sku = sku
        params.kind = Kind::Storage
    
        Client.new( auth ).storage_accounts.create(
            rg_name, name, params
        )
    end
end