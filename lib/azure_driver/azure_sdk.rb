# encoding: utf-8
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See License.txt in the project root for license information.

require "#{RUBY_LIB_LOCATION}/azure_driver/latest/module_definition.rb"

require 'azure_mgmt_authorization'
require 'azure_mgmt_billing'
require 'azure_mgmt_compute'
require 'azure_mgmt_monitor'
require 'azure_mgmt_network'
require 'azure_mgmt_resources'
require 'azure_mgmt_storage'
require 'azure_mgmt_subscriptions'
require 'azure_mgmt_consumption'

require "#{RUBY_LIB_LOCATION}/azure_driver/latest/latest_profile_client.rb"
