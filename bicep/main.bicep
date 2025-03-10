param adminuser string = 'atcadmin'
@secure()
param adminpass string

resource vmNsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: 'atcmineserv-nsg'
  location: 'australiaeast'
  properties: {
    securityRules: [
      {
        name: 'AllowClient'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '25565'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '10.200.0.0/26'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionSSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '10.200.0.64/26'
          destinationAddressPrefix: '10.200.0.0/26'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vmPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'atcmineserv-pip'
  location: 'australiaeast'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: 'atcmineserv'
    }
  }
}

resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: 'atcbastion-pip'
  location: 'australiaeast'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: 'atcbastion'
    }
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'atcmineserv-vnet'
  location: 'australiaeast'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.0.0/23'
      ]
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.200.0.64/26'
        }
      }
      {
        name: 'vmSubnet'
        properties: {
          addressPrefix: '10.200.0.0/26'
          networkSecurityGroup: {
            id: vmNsg.id
          }
        }
      }
    ]
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-05-01' = {
  name: 'atcmineserv-bastion'
  location: 'australiaeast'
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          publicIPAddress: {
            id: bastionPublicIP.id
          }
          subnet: {
            id: '${virtualNetwork.id}/subnets/AzureBastionSubnet'
          }
        }
      }
    ]
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: 'atcmineserv01-nic'
  location: 'australiaeast'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${virtualNetwork.id}/subnets/vmSubnet'
          }
          publicIPAddress: {
            id: vmPublicIP.id
          }
        }
      }
    ]
  }
}

resource atcmineserv 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'atcmineserv01'
  location: 'australiaeast'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_E2pds_v6'
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server-arm64'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: 'atcmineserv01_OsDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
        deleteOption: 'Delete'
      }
      dataDisks: []
      diskControllerType: 'SCSI'
    }
    osProfile: {
      computerName: 'atcmineserv01'
      adminUsername: adminuser
      adminPassword: adminpass
      linuxConfiguration: {
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
  }
}

resource atcmineservstorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  name: 'atcmineservbackup98689'
  location: 'australiaeast'
  tags: {}
  properties: {
    dnsEndpointType: 'Standard'
    allowedCopyScope: 'AAD'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: false
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(atcmineserv.id, atcmineservstorage.id, 'Storage Blob Data Contributor')
  scope: atcmineservstorage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: atcmineserv.identity.principalId
  }
}
