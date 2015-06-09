﻿# Load ADAL Assemblies
 
$adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
 
$adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
 
[System.Reflection.Assembly]::LoadFrom($adal)
 
[System.Reflection.Assembly]::LoadFrom($adalforms)

# Set Azure AD Tenant name
 
$adTenant = "a25fff9c-3f63-4fb2-9a8a-d9bdd0321f9a"

# Set well-known client ID for AzurePowerShell
 
$clientId = "1950a258-227b-4e31-a9cf-717495945fc2" 

# Set redirect URI for Azure PowerShell
 
$redirectUri = "urn:ietf:wg:oauth:2.0:oob"

# Set Resource URI to Azure Service Management API
 
$resourceAppIdURI = "https://management.core.windows.net/"

# Set Authority to Azure AD Tenant
 
$authority = "https://login.windows.net/$adTenant"

# Create Authentication Context tied to Azure AD Tenant
 
$authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

# Acquire token
 
$authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")

#this is needed otherwise the $schema below becomes empty
$schema='$schema'

$jsonBody = @"
{
	"properties": {
		"template": {
			"$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
			"contentVersion": "1.0.0.0",
			"parameters": {
				"adminUsername": {
					"type": "string",
					"defaultValue": "jarek",
					"metadata": {
						"description": "Administrator user name used when provisioning virtual machines (which also becomes a system user administrator in MongoDB)"
					}
				},
				"adminPassword": {
					"type": "securestring",
					"metadata": {
						"description": "Administrator password used when provisioning virtual machines (which is also a password for the system administrator in MongoDB)"
					}
				},
				"storageAccountName": {
					"type": "string",
					"defaultValue": "mongodbhasg",
					"metadata": {
						"description": "Unique namespace for the Storage Account where the Virtual Machine's disks will be placed (this name will be used as a prefix to create one or more storage accounts as per t-shirt size)"
					}
				},
				"location": {
					"type": "string",
					"defaultValue": "West US",
					"allowedValues": ["West US",
					"East US",
					"East Asia",
					"Southeast Asia",
					"West Europe"],
					"metadata": {
						"description": "Location where resources will be provisioned"
					}
				},
				"virtualNetworkName": {
					"type": "string",
					"defaultValue": "mongodbVnet",
					"metadata": {
						"description": "The arbitrary name of the virtual network provisioned for the MongoDB deployment"
					}
				},
				"subnetName": {
					"type": "string",
					"defaultValue": "mongodbSubnet",
					"metadata": {
						"description": "Subnet name for the virtual network that resources will be provisioned in to"
					}
				},
				"addressPrefix": {
					"type": "string",
					"defaultValue": "10.0.0.0/16",
					"metadata": {
						"description": "The network address space for the virtual network"
					}
				},
				"subnetPrefix": {
					"type": "string",
					"defaultValue": "10.0.0.0/24",
					"metadata": {
						"description": "The network address space for the virtual subnet"
					}
				},
				"nodeAddressPrefix": {
					"type": "string",
					"defaultValue": "10.0.0.1",
					"metadata": {
						"description": "The IP address prefix that will be used for constructing a static private IP address for each node in the cluster"
					}
				},
				"jumpbox": {
					"type": "string",
					"defaultValue": "Enabled",
					"allowedValues": ["Enabled",
					"Disabled"],
					"metadata": {
						"description": "The flag allowing to enable or disable provisioning of the jumpbox VM that can be used to access the MongoDB environment"
					}
				},
				"tshirtSize": {
					"type": "string",
					"defaultValue": "XSmall",
					"allowedValues": ["XSmall",
					"Small",
					"Medium",
					"Large",
					"XLarge",
					"XXLarge"],
					"metadata": {
						"description": "T-shirt size of the MongoDB deployment"
					}
				},
				"osFamily": {
					"type": "string",
					"defaultValue": "Ubuntu",
					"allowedValues": ["Ubuntu"],
					"metadata": {
						"description": "The target OS for the virtual machines running MongoDB"
					}
				},
				"mongodbVersion": {
					"type": "string",
					"defaultValue": "3.0.2",
					"metadata": {
						"description": "The version of the MongoDB packages to be deployed"
					}
				},
				"replicaSetName": {
					"type": "string",
					"defaultValue": "rs0",
					"metadata": {
						"description": "The name of the MongoDB replica set"
					}
				},
				"replicaSetKey": {
					"type": "string",
					"defaultValue": "Temp4now",
					"metadata": {
						"description": "The shared secret key for the MongoDB replica set"
					}
				}
			},
			"variables": {
				"_comment0": "/* T-shirt sizes may vary for different reasons, and some customers may want to modify these - so feel free to go ahead and define your favorite t-shirts */",
				"tshirtSizeXSmall": {
					"vmSizeMember": "Standard_D1",
					"vmSizeArbiter": "Standard_A1",
					"numberOfMembers": 1,
					"totalMemberCount": 2,
					"arbiter": "Enabled",
					"vmTemplate": "[concat(variables('templateBaseUrl'), 'member-resources-D1.json')]",
					"storageAccountCount": 1,
					"dataDiskSize": 100
				},
				"tshirtSizeSmall": {
					"vmSizeMember": "Standard_D1",
					"vmSizeArbiter": "Standard_A1",
					"numberOfMembers": 2,
					"totalMemberCount": 3,
					"arbiter": "Disabled",
					"vmTemplate": "[concat(variables('templateBaseUrl'), 'member-resources-D1.json')]",
					"storageAccountCount": 1,
					"dataDiskSize": 100
				},
				"tshirtSizeMedium": {
					"vmSizeMember": "Standard_D2",
					"vmSizeArbiter": "Standard_A1",
					"numberOfMembers": 3,
					"totalMemberCount": 4,
					"arbiter": "Enabled",
					"vmTemplate": "[concat(variables('templateBaseUrl'), 'member-resources-D2.json')]",
					"storageAccountCount": 2,
					"dataDiskSize": 250
				},
				"tshirtSizeLarge": {
					"vmSizeMember": "Standard_D2",
					"vmSizeArbiter": "Standard_A1",
					"numberOfMembers": 7,
					"totalMemberCount": 8,
					"arbiter": "Enabled",
					"vmTemplate": "[concat(variables('templateBaseUrl'), 'member-resources-D2.json')]",
					"storageAccountCount": 4,
					"dataDiskSize": 250
				},
				"tshirtSizeXLarge": {
					"vmSizeMember": "Standard_D3",
					"vmSizeArbiter": "Standard_A1",
					"numberOfMembers": 7,
					"totalMemberCount": 8,
					"arbiter": "Enabled",
					"vmTemplate": "[concat(variables('templateBaseUrl'), 'member-resources-D3.json')]",
					"storageAccountCount": 4,
					"dataDiskSize": 500
				},
				"tshirtSizeXXLarge": {
					"vmSizeMember": "Standard_D3",
					"vmSizeArbiter": "Standard_A1",
					"numberOfMembers": 15,
					"totalMemberCount": 16,
					"arbiter": "Disabled",
					"vmTemplate": "[concat(variables('templateBaseUrl'), 'member-resources-D3.json')]",
					"storageAccountCount": 8,
					"dataDiskSize": 500
				},
				"osFamilyUbuntu": {
					"osName": "ubuntu",
					"installerBaseUrl": "http://repo.mongodb.org/apt/ubuntu",
					"installerPackages": "mongodb-org",
					"imagePublisher": "Canonical",
					"imageOffer": "UbuntuServer",
					"imageSKU": "14.04.2-LTS"
				},
				"vmStorageAccountContainerName": "vhd-mongodb",
				"vmStorageAccountDomain": ".blob.core.windows.net",
				"vnetID": "[resourceId('Microsoft.Network/virtualNetworks', parameters('virtualNetworkName'))]",
				"sharedScriptUrl": "[concat('https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/shared_scripts/', variables('osFamilySpec').osName, '/')]",
				"scriptUrl": "https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/mongodb-high-availability/",
				"templateBaseUrl": "[variables('scriptUrl')]",
				"jumpboxTemplateEnabled": "jumpbox-resources.json",
				"jumpboxTemplateDisabled": "empty-resources.json",
				"arbiterTemplateEnabled": "arbiter-resources.json",
				"arbiterTemplateDisabled": "empty-resources.json",
				"sharedTemplateUrl": "[concat(variables('templateBaseUrl'), 'shared-resources.json')]",
				"jumpboxTemplateUrl": "[concat(variables('templateBaseUrl'), variables(concat('jumpboxTemplate', parameters('jumpbox'))))]",
				"arbiterTemplateUrl": "[concat(variables('templateBaseUrl'), variables(concat('arbiterTemplate', variables('clusterSpec').arbiter)))]",
				"commonSettings": {
					"availabilitySetName": "mongodbAvailSet",
					"location": "[parameters('location')]"
				},
				"storageSettings": {
					"vhdStorageAccountName": "[parameters('storageAccountName')]",
					"vhdContainerName": "[variables('vmStorageAccountContainerName')]",
					"destinationVhdsContainer": "[concat('https://', parameters('storageAccountName'), variables('vmStorageAccountDomain'), '/', variables('vmStorageAccountContainerName'), '/')]",
					"storageAccountCount": "[variables('clusterSpec').storageAccountCount]"
				},
				"networkSettings": {
					"virtualNetworkName": "[parameters('virtualNetworkName')]",
					"addressPrefix": "[parameters('addressPrefix')]",
					"subnetName": "[parameters('subnetName')]",
					"subnetPrefix": "[parameters('subnetPrefix')]",
					"subnetRef": "[concat(variables('vnetID'), '/subnets/', parameters('subnetName'))]",
					"machineIpPrefix": "[parameters('nodeAddressPrefix')]"
				},
				"machineSettings": {
					"adminUsername": "[parameters('adminUsername')]",
					"adminPassword": "[parameters('adminPassword')]",
					"machineNamePrefix": "mongodb-",
					"osImageReference": {
						"publisher": "[variables('osFamilySpec').imagePublisher]",
						"offer": "[variables('osFamilySpec').imageOffer]",
						"sku": "[variables('osFamilySpec').imageSKU]",
						"version": "latest"
					}
				},
				"clusterSpec": "[variables(concat('tshirtSize', parameters('tshirtSize')))]",
				"osFamilySpec": "[variables(concat('osFamily', parameters('osFamily')))]",
				"installCommand": "[concat('bash mongodb-', variables('osFamilySpec').osName, '-install.sh', ' -i ', variables('osFamilySpec').installerBaseUrl, ' -b ', variables('osFamilySpec').installerPackages, ' -r ', parameters('replicaSetName'), ' -k ', parameters('replicaSetKey'), ' -u ', parameters('adminUsername'), ' -p ', parameters('adminPassword'), ' -x ', variables('networkSettings').machineIpPrefix, ' -n ', variables('clusterSpec').totalMemberCount)]",
				"vmScripts": {
					"scriptsToDownload": ["[concat(variables('scriptUrl'), 'mongodb-', variables('osFamilySpec').osName, '-install.sh')]",
					"[concat(variables('sharedScriptUrl'), 'vm-disk-utils-0.1.sh')]"],
					"regularNodeInstallCommand": "[variables('installCommand')]",
					"lastNodeInstallCommand": "[concat(variables('installCommand'), ' -l')]",
					"arbiterNodeInstallCommand": "[concat(variables('installCommand'), ' -a')]"
				},
				"_comment1": "/* The weird list of values below helps partition VM disks across multiple storage accounts to achieve a better throughput */",
				"_comment2": "/* Feel free to modify the default allocations if you are comfortable and understand what you are doing */",
				"storageAccountForXSmall_0": "0",
				"storageAccountForXSmall_1": "0",
				"storageAccountForSmall_0": "0",
				"storageAccountForSmall_1": "0",
				"storageAccountForSmall_2": "0",
				"storageAccountForMedium_0": "0",
				"storageAccountForMedium_1": "0",
				"storageAccountForMedium_2": "0",
				"storageAccountForMedium_3": "0",
				"storageAccountForLarge_0": "0",
				"storageAccountForLarge_1": "1",
				"storageAccountForLarge_2": "2",
				"storageAccountForLarge_3": "3",
				"storageAccountForLarge_4": "0",
				"storageAccountForLarge_5": "1",
				"storageAccountForLarge_6": "2",
				"storageAccountForLarge_7": "3",
				"storageAccountForXLarge_0": "0",
				"storageAccountForXLarge_1": "1",
				"storageAccountForXLarge_2": "2",
				"storageAccountForXLarge_3": "3",
				"storageAccountForXLarge_4": "0",
				"storageAccountForXLarge_5": "1",
				"storageAccountForXLarge_6": "2",
				"storageAccountForXLarge_7": "3",
				"storageAccountForXXLarge_0": "0",
				"storageAccountForXXLarge_1": "1",
				"storageAccountForXXLarge_2": "2",
				"storageAccountForXXLarge_3": "3",
				"storageAccountForXXLarge_4": "4",
				"storageAccountForXXLarge_5": "5",
				"storageAccountForXXLarge_6": "6",
				"storageAccountForXXLarge_7": "7",
				"storageAccountForXXLarge_8": "0",
				"storageAccountForXXLarge_9": "1",
				"storageAccountForXXLarge_10": "2",
				"storageAccountForXXLarge_11": "3",
				"storageAccountForXXLarge_12": "4",
				"storageAccountForXXLarge_13": "5",
				"storageAccountForXXLarge_14": "6",
				"storageAccountForXXLarge_15": "7"
			},
			"resources": [{
				"name": "shared-resources",
				"type": "Microsoft.Resources/deployments",
				"apiVersion": "2015-01-01",
				"properties": {
					"mode": "Incremental",
					"templateLink": {
						"uri": "[variables('sharedTemplateUrl')]",
						"contentVersion": "1.0.0.0"
					},
					"parameters": {
						"commonSettings": {
							"value": "[variables('commonSettings')]"
						},
						"storageSettings": {
							"value": "[variables('storageSettings')]"
						},
						"networkSettings": {
							"value": "[variables('networkSettings')]"
						}
					}
				}
			},
			{
				"name": "jumpbox-resources",
				"type": "Microsoft.Resources/deployments",
				"apiVersion": "2015-01-01",
				"dependsOn": ["[concat('Microsoft.Resources/deployments/', 'shared-resources')]"],
				"properties": {
					"mode": "Incremental",
					"templateLink": {
						"uri": "[variables('jumpboxTemplateUrl')]",
						"contentVersion": "1.0.0.0"
					},
					"parameters": {
						"commonSettings": {
							"value": "[variables('commonSettings')]"
						},
						"storageSettings": {
							"value": {
								"vhdStorageAccountName": "[concat(variables('storageSettings').vhdStorageAccountName, '0')]",
								"vhdContainerName": "[variables('storageSettings').vhdContainerName]",
								"destinationVhdsContainer": "[concat('https://', variables('storageSettings').vhdStorageAccountName, '0', variables('vmStorageAccountDomain'), '/', variables('storageSettings').vhdContainerName, '/')]"
							}
						},
						"networkSettings": {
							"value": "[variables('networkSettings')]"
						},
						"machineSettings": {
							"value": "[variables('machineSettings')]"
						}
					}
				}
			},
			{
				"type": "Microsoft.Resources/deployments",
				"name": "[concat('member-resources', copyindex())]",
				"apiVersion": "2015-01-01",
				"dependsOn": ["[concat('Microsoft.Resources/deployments/', 'shared-resources')]"],
				"copy": {
					"name": "memberNodesLoop",
					"count": "[variables('clusterSpec').numberOfMembers]"
				},
				"properties": {
					"mode": "Incremental",
					"templateLink": {
						"uri": "[variables('clusterSpec').vmTemplate]",
						"contentVersion": "1.0.0.0"
					},
					"parameters": {
						"commonSettings": {
							"value": "[variables('commonSettings')]"
						},
						"storageSettings": {
							"value": {
								"vhdStorageAccountName": "[concat(variables('storageSettings').vhdStorageAccountName, variables(concat('storageAccountFor', parameters('tshirtSize'), '_', copyindex())))]",
								"vhdContainerName": "[variables('storageSettings').vhdContainerName]",
								"destinationVhdsContainer": "[concat('https://', variables('storageSettings').vhdStorageAccountName, variables(concat('storageAccountFor', parameters('tshirtSize'), '_', copyindex())), variables('vmStorageAccountDomain'), '/', variables('storageSettings').vhdContainerName, '/')]"
							}
						},
						"networkSettings": {
							"value": "[variables('networkSettings')]"
						},
						"machineSettings": {
							"value": {
								"adminUsername": "[variables('machineSettings').adminUsername]",
								"adminPassword": "[variables('machineSettings').adminPassword]",
								"machineNamePrefix": "[variables('machineSettings').machineNamePrefix]",
								"osImageReference": "[variables('machineSettings').osImageReference]",
								"vmSize": "[variables('clusterSpec').vmSizeMember]",
								"dataDiskSize": "[variables('clusterSpec').dataDiskSize]",
								"machineIndex": "[copyindex()]",
								"vmScripts": "[variables('vmScripts').scriptsToDownload]",
								"commandToExecute": "[variables('vmScripts').regularNodeInstallCommand]"
							}
						}
					}
				}
			},
			{
				"type": "Microsoft.Resources/deployments",
				"name": "lastmember-resources",
				"apiVersion": "2015-01-01",
				"dependsOn": ["memberNodesLoop"],
				"properties": {
					"mode": "Incremental",
					"templateLink": {
						"uri": "[variables('clusterSpec').vmTemplate]",
						"contentVersion": "1.0.0.0"
					},
					"parameters": {
						"commonSettings": {
							"value": "[variables('commonSettings')]"
						},
						"storageSettings": {
							"value": {
								"vhdStorageAccountName": "[concat(variables('storageSettings').vhdStorageAccountName, variables(concat('storageAccountFor', parameters('tshirtSize'), '_', variables('clusterSpec').numberOfMembers)))]",
								"vhdContainerName": "[variables('storageSettings').vhdContainerName]",
								"destinationVhdsContainer": "[concat('https://', variables('storageSettings').vhdStorageAccountName, variables(concat('storageAccountFor', parameters('tshirtSize'), '_', variables('clusterSpec').numberOfMembers)), variables('vmStorageAccountDomain'), '/', variables('storageSettings').vhdContainerName, '/')]"
							}
						},
						"networkSettings": {
							"value": "[variables('networkSettings')]"
						},
						"machineSettings": {
							"value": {
								"adminUsername": "[variables('machineSettings').adminUsername]",
								"adminPassword": "[variables('machineSettings').adminPassword]",
								"machineNamePrefix": "[variables('machineSettings').machineNamePrefix]",
								"osImageReference": "[variables('machineSettings').osImageReference]",
								"vmSize": "[variables('clusterSpec').vmSizeMember]",
								"dataDiskSize": "[variables('clusterSpec').dataDiskSize]",
								"machineIndex": "[variables('clusterSpec').numberOfMembers]",
								"vmScripts": "[variables('vmScripts').scriptsToDownload]",
								"commandToExecute": "[variables('vmScripts').lastNodeInstallCommand]"
							}
						}
					}
				}
			},
			{
				"name": "arbiter-resources",
				"type": "Microsoft.Resources/deployments",
				"apiVersion": "2015-01-01",
				"dependsOn": ["[concat('Microsoft.Resources/deployments/', 'lastmember-resources')]"],
				"properties": {
					"mode": "Incremental",
					"templateLink": {
						"uri": "[variables('arbiterTemplateUrl')]",
						"contentVersion": "1.0.0.0"
					},
					"parameters": {
						"commonSettings": {
							"value": "[variables('commonSettings')]"
						},
						"storageSettings": {
							"value": {
								"vhdStorageAccountName": "[concat(variables('storageSettings').vhdStorageAccountName, '0')]",
								"vhdContainerName": "[variables('storageSettings').vhdContainerName]",
								"destinationVhdsContainer": "[concat('https://', variables('storageSettings').vhdStorageAccountName, '0', variables('vmStorageAccountDomain'), '/', variables('storageSettings').vhdContainerName, '/')]"
							}
						},
						"networkSettings": {
							"value": "[variables('networkSettings')]"
						},
						"machineSettings": {
							"value": {
								"adminUsername": "[variables('machineSettings').adminUsername]",
								"adminPassword": "[variables('machineSettings').adminPassword]",
								"machineNamePrefix": "[variables('machineSettings').machineNamePrefix]",
								"osImageReference": "[variables('machineSettings').osImageReference]",
								"vmSize": "[variables('clusterSpec').vmSizeArbiter]",
								"vmScripts": "[variables('vmScripts').scriptsToDownload]",
								"commandToExecute": "[concat(variables('vmScripts').arbiterNodeInstallCommand)]"
							}
						}
					}
				}
			}]
		},
		"parameters": {
		"adminPassword": { "value": "Temp4now" }
		},
		"mode": "Incremental"
	}
}
"@


[byte[]]$requestBody = 
    [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
 
# Create Authorization Header
 
$authHeader = $authResult.CreateAuthorizationHeader() 

# Set HTTP request headers to include Authorization header
 
$requestHeader = @{"x-ms-version" = "2013-10-01";"Authorization" = $authHeader}
 
# Encode the JSON web request body

$contentType = "application/json;charset=utf-8"

# Set Azure deployment values
$subscriptionId = "f6c0cb91-aaca-4ff3-9bd9-4be01af16a8b"
$resourceGroupName = "jmnrestrg"
$deploymentName = "sharedresourcesdeploy"
 
# Call Azure Service Management REST API to add Autoscale settings
#$azureMgmtUri = "https://management.azure.com/subscriptions/$subscriptionId/resourcegroups/jmrestrg?api-version=2015-01-01"  
$azureMgmtUri = "https://management.azure.com/subscriptions/f6c0cb91-aaca-4ff3-9bd9-4be01af16a8b/resourcegroups/jmsimplenestedrg/deployments/simple-nested-rest/validate?api-version=2015-01-01" 
#$azureMgmtUri = "https://management.azure.com/subscriptions/f6c0cb91-aaca-4ff3-9bd9-4be01af16a8b/resourcegroups?api-version=2014-04-01-preview"
 
$response = Invoke-RestMethod `
    -Uri $azureMgmtUri `
    -Method Post `
    -Headers $requestHeader `
    -Body $jsonBody `
    -ContentType $contentType

$azureMgmtUri = "https://management.azure.com/subscriptions/f6c0cb91-aaca-4ff3-9bd9-4be01af16a8b/resourcegroups/jmmongodb-ha/deployments/mongodb-ha?api-version=2015-01-01" 

$response = Invoke-RestMethod `
    -Uri $azureMgmtUri `
    -Method Put `
    -Headers $requestHeader `
    -Body $jsonBody `
    -ContentType $contentType `
    -Verbose

$response = Invoke-RestMethod 
    -Uri $azureMgmtUri `
    -Method Get `
    -Headers $requestHeader

