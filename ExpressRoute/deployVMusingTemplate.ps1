Login-AzureRmAccount -SubscriptionId f6c0cb91-aaca-4ff3-9bd9-4be01af16a8b

Select-AzureRmSubscription -SubscriptionId 7274c071-c869-42da-a02e-7f923a954964 

Add-AzureRmVhd -ResourceGroupName mayocustomimagesrg -Destination https://mayocustomimagessa.blob.core.windows.net/images/rhel72jm-azure.vhd -LocalFilePath C:\install_images\images\rhel\rhel72-osazure.vhd

New-AzureRmResourceGroupDeployment -ResourceGroupName mcredhatimagesrg -Name 1strhel67deployment -Force -TemplateUri https://raw.githubusercontent.com/jarekmisz/azure-scripts/master/ExpressRoute/rhelNoDataDiskVM.json -Debug
