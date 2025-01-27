targetScope = 'subscription'

/*
** Spoke Network Infrastructure
** Copyright (C) 2023 Microsoft, Inc.
** All Rights Reserved
**
***************************************************************************
**
** The Spoke Network consists of a virtual network that hosts resources that
** are associated with the web app workload (e.g. private endpoints).
*/

import { DiagnosticSettings } from '../types/DiagnosticSettings.bicep'
import { DeploymentSettings } from '../types/DeploymentSettings.bicep'

// ========================================================================
// PARAMETERS
// ========================================================================

@description('The deployment settings to use for this deployment.')
param deploymentSettings DeploymentSettings

@description('The diagnostic settings to use for logging and metrics.')
param diagnosticSettings DiagnosticSettings

@description('The resource names for the resources to be created.')
param resourceNames object

/*
** Dependencies
*/
@description('The ID of the Log Analytics workspace to use for diagnostics and logging.')
param logAnalyticsWorkspaceId string = ''

@description('If set, the ID of the table holding the outbound route to the firewall in the hub network')
param firewallInternalIpAddress string = ''

/*
** Settings
*/

@description('The CIDR block to use for the address prefix of this virtual network.')
param addressPrefix string = '10.0.16.0/20'



// ========================================================================
// VARIABLES
// ========================================================================

var enableFirewall = !empty(firewallInternalIpAddress)

// The tags to apply to all resources in this workload
var moduleTags = union(deploymentSettings.tags, deploymentSettings.workloadTags)

// The subnet prefixes for the individual subnets inside the virtual network
var subnetPrefixes = [ for i in range(0, 16): cidrSubnet(addressPrefix, 26, i)]

// When creating the virtual network, we need to set up a service delegation for app services.
var appServiceDelegation = [
  {
    name: 'ServiceDelegation'
    properties: {
      serviceName: 'Microsoft.Web/serverFarms'
    }
  }
]

// When creating the virtual network, we need to set up a service delegation for container apps.
var containerAppDelegation = [
  {
    name: 'ServiceDelegation'
    properties: {
      serviceName: 'Microsoft.App/environments'
    }
  }
]

// Network security group rules
var allowHttpInbound = {
  name: 'Allow-HTTP-Inbound'
  properties: {
    access: 'Allow'
    description: 'Allow HTTPS inbound traffic'
    destinationAddressPrefix: '*'
    destinationPortRange: '80'
    direction: 'Inbound'
    priority: 100
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}

var allowHttpsInbound = {
  name: 'Allow-HTTPS-Inbound'
  properties: {
    access: 'Allow'
    description: 'Allow HTTPS inbound traffic'
    destinationAddressPrefix: '*'
    destinationPortRange: '443'
    direction: 'Inbound'
    priority: 105
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}

var allowSqlInbound = {
  name: 'Allow-SQL-Inbound'
  properties: {
    access: 'Allow'
    description: 'Allow SQL inbound traffic'
    destinationAddressPrefix: '*'
    destinationPortRange: '1433'
    direction: 'Inbound'
    priority: 110
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}

var denyAllInbound = {
  name: 'Deny-All-Inbound'
  properties: {
    access: 'Deny'
    description: 'Deny all inbound traffic'
    destinationAddressPrefix: '*'
    destinationPortRange: '*'
    direction: 'Inbound'
    priority: 1000
    protocol: '*'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}

// ACAE Inbound rules
// https://learn.microsoft.com/azure/container-apps/firewall-integration

var containerAppsAllowHttpInbound = {
  name: 'Allow-Container-Apps-HTTP-Inbound'
  properties: {
    access: 'Allow'
    description: 'Allow HTTP inbound traffic'
    destinationAddressPrefix: '*'
    destinationPortRange: '31080'
    direction: 'Inbound'
    priority: 120
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}

var containerAppsAllowHttpsInbound = {
  name: 'Allow-Container-Apps-HTTPS-Inbound'
  properties: {
    access: 'Allow'
    description: 'Allow HTTP inbound traffic'
    destinationAddressPrefix: '*'
    destinationPortRange: '31443'
    direction: 'Inbound'
    priority: 125
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}

var allowAzureLoadBalancerInbound = {
  name: 'Allow-Azure-Load-Balancer'
  properties: {
    access: 'Allow'
    description: 'Allow Azure Load Balancer traffic'
    destinationAddressPrefix: '*'
    destinationPortRange: '30000-32676'
    direction: 'Inbound'
    priority: 130
    protocol: '*'
    sourceAddressPrefix: 'AzureLoadBalancer'
    sourcePortRange: '*'
  }
}

// ACAE Outbound rules

var allowContainerRegistryOutbound = {
  name: 'Allow-Container-Registry-Outbound'
  properties: {
    access: 'Allow'
    description: 'Allow Container Registry outbound traffic'
    destinationAddressPrefix: 'MicrosoftContainerRegistry'
    destinationPortRange: '443'
    direction: 'Outbound'
    priority: 140
    protocol: 'Tcp'
    sourceAddressPrefix: 'VirtualNetwork'
    sourcePortRange: '*'
  }
}

// Dependency of the container registry service tag
var allowFrontDoorOutbound = {
  name: 'Allow-FrontDoor-Outbound'
  properties: {
    access: 'Allow'
    description: 'Allow Front Door first party outbound traffic (dependency of the container registry service tag)'
    destinationAddressPrefix: 'AzureFrontDoor.FirstParty'
    destinationPortRange: '443'
    direction: 'Outbound'
    priority: 150
    protocol: 'Tcp'
    sourceAddressPrefix: 'VirtualNetwork'
    sourcePortRange: '*'
  }
}

var allowEntraIdOutbound = {
  name: 'Allow-EntraId-Outbound'
  properties: {
    access: 'Allow'
    description: 'Allow EntraId outbound traffic'
    destinationAddressPrefix: 'AzureActiveDirectory'
    destinationPortRange: '443'
    direction: 'Outbound'
    priority: 160
    protocol: 'Tcp'
    sourceAddressPrefix: 'VirtualNetwork'
    sourcePortRange: '*'
  }
}

// Sets up the route table when there is one specified.
var routeTableSettings = enableFirewall ? {
  routeTable: { id: routeTable.outputs.id }
} : {}

// True if deploying into the primary region in a multi-region deployment, otherwise false
var isPrimaryLocation = deploymentSettings.location == deploymentSettings.primaryLocation


// ========================================================================
// AZURE MODULES
// ========================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: resourceNames.spokeResourceGroup
}

module apiInboundNSG '../core/network/network-security-group.bicep' = {
  name: 'spoke-api-inbound-nsg-${deploymentSettings.resourceToken}'
  scope: resourceGroup
  params: {
    name: resourceNames.spokeApiInboundNSG
    location: deploymentSettings.location
    tags: moduleTags

    // Dependencies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId

    // Settings
    diagnosticSettings: diagnosticSettings
    securityRules: [
      allowHttpsInbound
      denyAllInbound
    ]
  }
}

module apiOutboundNSG '../core/network/network-security-group.bicep' = {
  name: 'spoke-api-outbound-nsg-${deploymentSettings.resourceToken}'
  scope: resourceGroup
  params: {
    name: resourceNames.spokeApiOutboundNSG
    location: deploymentSettings.location
    tags: moduleTags

    // Dependencies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId

    // Settings
    diagnosticSettings: diagnosticSettings
    securityRules: [
      denyAllInbound
    ]
  }
}

module privateEndpointNSG '../core/network/network-security-group.bicep' = {
  name: 'spoke-pep-nsg-${deploymentSettings.resourceToken}'
  scope: resourceGroup
  params: {
    name: resourceNames.spokePrivateEndpointNSG
    location: deploymentSettings.location
    tags: moduleTags

    // Dependencies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId

    // Settings
    diagnosticSettings: diagnosticSettings
    securityRules: [
      allowHttpsInbound
      allowSqlInbound
      denyAllInbound
    ]
  }
}

module webInboundNSG '../core/network/network-security-group.bicep' = {
  name: 'spoke-web-inbound-nsg-${deploymentSettings.resourceToken}'
  scope: resourceGroup
  params: {
    name: resourceNames.spokeWebInboundNSG
    location: deploymentSettings.location
    tags: moduleTags

    // Dependencies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId

    // Settings
    diagnosticSettings: diagnosticSettings
    securityRules: [
      allowHttpsInbound
      denyAllInbound
    ]
  }
}

module webOutboundNSG '../core/network/network-security-group.bicep' = {
  name: 'spoke-web-outbound-nsg-${deploymentSettings.resourceToken}'
  scope: resourceGroup
  params: {
    name: resourceNames.spokeWebOutboundNSG
    location: deploymentSettings.location
    tags: moduleTags

    // Dependencies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId

    // Settings
    diagnosticSettings: diagnosticSettings
    securityRules: [
      denyAllInbound
    ]
  }
}

module containerAppsEnvironmentNSG '../core/network/network-security-group.bicep' = {
  name: isPrimaryLocation ? 'spoke-container-apps-environment-nsg-0' : 'spoke-container-apps-environment-nsg-1'
  scope: resourceGroup
  params: {
    name: resourceNames.spokeContainerAppsEnvironmentNSG
    location: deploymentSettings.location
    tags: moduleTags

    // Dependencies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId

    // Settings
    diagnosticSettings: diagnosticSettings
    securityRules: [
      allowHttpInbound
      allowHttpsInbound
      containerAppsAllowHttpInbound
      containerAppsAllowHttpsInbound
      allowAzureLoadBalancerInbound
      allowContainerRegistryOutbound
      allowFrontDoorOutbound
      allowEntraIdOutbound
    ]
  }
}

module virtualNetwork '../core/network/virtual-network.bicep' = {
  name: 'spoke-virtual-network-${deploymentSettings.resourceToken}'
  scope: resourceGroup
  params: {
    name: resourceNames.spokeVirtualNetwork
    location: deploymentSettings.location
    tags: moduleTags

    // Dependencies
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId

    // Settings
    addressPrefix: addressPrefix
    diagnosticSettings: diagnosticSettings
    subnets: [
      {
        name: resourceNames.spokePrivateEndpointSubnet
        properties: {
          addressPrefix: subnetPrefixes[0]
          networkSecurityGroup: { id: privateEndpointNSG.outputs.id }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: resourceNames.spokeApiInboundSubnet
        properties: {
          addressPrefix: subnetPrefixes[1]
          networkSecurityGroup: { id: apiInboundNSG.outputs.id }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: resourceNames.spokeApiOutboundSubnet
        properties: union({
          addressPrefix: subnetPrefixes[2]
          delegations: appServiceDelegation
          networkSecurityGroup: { id: apiOutboundNSG.outputs.id }
          privateEndpointNetworkPolicies: 'Enabled'
        }, routeTableSettings)
      }
      {
        name: resourceNames.spokeWebInboundSubnet
        properties: {
          addressPrefix: subnetPrefixes[3]
          networkSecurityGroup: { id: webInboundNSG.outputs.id }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: resourceNames.spokeWebOutboundSubnet
        properties: union({
          addressPrefix: subnetPrefixes[4]
          delegations: appServiceDelegation
          networkSecurityGroup: { id: webOutboundNSG.outputs.id }
          privateEndpointNetworkPolicies: 'Enabled'
        }, routeTableSettings)
      }
      {
        name: resourceNames.spokeContainerAppsEnvironmentSubnet
        properties: union({
          addressPrefix: subnetPrefixes[5]
          delegations: containerAppDelegation
          networkSecurityGroup: { id: containerAppsEnvironmentNSG.outputs.id }
          privateEndpointNetworkPolicies: 'Enabled'
        }, routeTableSettings)
      }]
  }
}

module routeTable '../core/network/route-table.bicep' = if (enableFirewall) {
  name: 'spoke-route-table-${deploymentSettings.resourceToken}'
  scope: resourceGroup
  params: {
    name: resourceNames.spokeRouteTable
    location: deploymentSettings.location
    tags: moduleTags

    // Settings
    routes: [
      {
        name: 'defaultEgress'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: firewallInternalIpAddress
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}


var virtualNetworkLinks = [
  {
    vnetName: virtualNetwork.outputs.name
    vnetId: virtualNetwork.outputs.id
    registrationEnabled: false
  }
]

module privateDnsZones './private-dns-zones.bicep' = {
  name: 'spoke-prvt-dns-zone-deploy-${deploymentSettings.resourceToken}'
  params:{
    createDnsZone: false //we are reusing the existing DNS zone and linking a vnet
    deploymentSettings: deploymentSettings
    hubResourceGroupName: resourceNames.hubResourceGroup
    virtualNetworkLinks: virtualNetworkLinks
  }
}

// ========================================================================
// OUTPUTS
// ========================================================================

output virtual_network_id string = virtualNetwork.outputs.id
output virtual_network_name string = virtualNetwork.outputs.name
output subnets object = virtualNetwork.outputs.subnets
