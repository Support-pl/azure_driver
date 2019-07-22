# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.


require 'latest/module_definition'

require 'latest/modules/authorization_profile_module'
require 'latest/modules/billing_profile_module'
require 'latest/modules/compute_profile_module'
require 'latest/modules/monitor_profile_module'
require 'latest/modules/network_profile_module'
require 'latest/modules/resources_profile_module'
require 'latest/modules/storage_profile_module'
require 'latest/modules/subscriptions_profile_module'
require 'latest/modules/consumption_profile_module'

module Azure::Profiles::Latest
  #
  # Client class for the Latest profile SDK.
  #
  class Client
    include MsRestAzure::Common::Configurable

    attr_reader :authorization, :billing, :compute, :monitor, :network, :resources, :storage, :subscriptions, :consumption

    #
    # Initializes a new instance of the Client class.
    # @param options [Hash] hash of client options.
    #    options = {
    #      tenant_id: 'YOUR TENANT ID',
    #      client_id: 'YOUR CLIENT ID',
    #      client_secret: 'YOUR CLIENT SECRET',
    #      subscription_id: 'YOUR SUBSCRIPTION ID',
    #      credentials: credentials,
    #      active_directory_settings: active_directory_settings,
    #      base_url: 'YOUR BASE URL',
    #      options: options
    #    }
    #   'credentials' are optional and if not passed in the hash, will be obtained
    #   from MsRest::TokenCredentials using MsRestAzure::ApplicationTokenProvider.
    #
    #   Also, base_url, active_directory_settings & options are optional.
    #
    def initialize(options = {})
      if options.is_a?(Hash) && options.length == 0
        @options = setup_default_options
      else
        @options = options
      end

      reset!(options)

      base_url = options[:base_url].nil? ? nil:options[:base_url]
      sdk_options = options[:options].nil? ? nil:options[:options]

      @authorization = AuthorizationAdapter.new(self, base_url, sdk_options)
      @billing = BillingAdapter.new(self, base_url, sdk_options)
      @compute = ComputeAdapter.new(self, base_url, sdk_options)
      @monitor = MonitorAdapter.new(self, base_url, sdk_options)
      @network = NetworkAdapter.new(self, base_url, sdk_options)
      @resources = ResourcesAdapter.new(self, base_url, sdk_options)
      @storage = StorageAdapter.new(self, base_url, sdk_options)
      @subscriptions = SubscriptionsAdapter.new(self, base_url, sdk_options)
      @consumption = ConsumptionAdapter.new(self, base_url, sdk_options)
    end

    class AuthorizationAdapter
      attr_accessor :mgmt

      def initialize(context, base_url, options)
        @mgmt = Azure::Profiles::Latest::Authorization::Mgmt::AuthorizationManagementClass.new(context, base_url, options)
      end
    end

    class BillingAdapter
      attr_accessor :mgmt

      def initialize(context, base_url, options)
        @mgmt = Azure::Profiles::Latest::Billing::Mgmt::BillingManagementClass.new(context, base_url, options)
      end
    end

    class ComputeAdapter
      attr_accessor :mgmt

      def initialize(context, base_url, options)
        @mgmt = Azure::Profiles::Latest::Compute::Mgmt::ComputeManagementClass.new(context, base_url, options)
      end
    end

    class MonitorAdapter
      attr_accessor :mgmt

      def initialize(context, base_url, options)
        @mgmt = Azure::Profiles::Latest::Monitor::Mgmt::MonitorManagementClass.new(context, base_url, options)
      end
    end

    class NetworkAdapter
      attr_accessor :mgmt

      def initialize(context, base_url, options)
        @mgmt = Azure::Profiles::Latest::Network::Mgmt::NetworkManagementClass.new(context, base_url, options)
      end
    end

    class ResourcesAdapter
      attr_accessor :mgmt

      def initialize(context, base_url, options)
        @mgmt = Azure::Profiles::Latest::Resources::Mgmt::ResourcesManagementClass.new(context, base_url, options)
      end
    end

    class StorageAdapter
      attr_accessor :mgmt

      def initialize(context, base_url, options)
        @mgmt = Azure::Profiles::Latest::Storage::Mgmt::StorageManagementClass.new(context, base_url, options)
      end
    end

    class SubscriptionsAdapter
      attr_accessor :mgmt

      def initialize(context, base_url, options)
        @mgmt = Azure::Profiles::Latest::Subscriptions::Mgmt::SubscriptionsManagementClass.new(context, base_url, options)
      end
    end

    class ConsumptionAdapter
      attr_accessor :mgmt

      def initialize(context, base_url, options)
        @mgmt = Azure::Profiles::Latest::Consumption::Mgmt::ConsumptionManagementClass.new(context, base_url, options)
      end
    end
  end
end
