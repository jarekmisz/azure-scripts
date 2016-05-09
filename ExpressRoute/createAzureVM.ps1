# Login-AzureRmAccount -SubscriptionId 3796604e-350d-40ea-8d8d-aca340420104

# Set to Windows, RHEL, or ubuntu
$osName = "RHEL"
# Set to expressroute if it's needed, otherwise a public vnet will be created
$network = "public"
# Since RG doesn't contain all the objects, need prefix for cleanup
$prefix = "cliqr";
$vmName = "CLLPCQR001A";
#$vmSize="Standard_D3_v2";
$vmSize="Standard_D1_v2";
$locName="northcentralus";
# Set to custom, if custom image is used, otherwise a gallery image will be use
$imageType = "custom";
# resource group
$rgName = $prefix + "infrarg";
# storage account
$saName = $prefix + "infrasa";
# The images will be copied from the master storage account only on the first execution. Increase the counter to make sure the copy is not repeated every time a new VM is created in a given sa
$sequence=2

New-AzureRmResourceGroup -Name $rgName -Location $locName;

$saType="Standard_LRS";
New-AzureRmStorageAccount -Name $saName -ResourceGroupName $rgName -Type $saType -Location $locName;


if ($imageType -eq "custom") {
   $dest='https://' + $saName + '.blob.core.windows.net/images'
   if($sequence -eq 1) {
      # Need to copy the custom image from the master copy location when the new storage account is created
      # Need to install AzCopy before running the command!
      $destKeys=Get-AzureRmStorageAccountKey -ResourceGroupName $rgName -Name $saName;
      $srcKeys= Get-AzureRmStorageAccountKey  -ResourceGroupName mayocustomimagesrg -Name mayocustomimagessa;
      $srcKey=$srcKeys.Key1;
      $destKey=$destKeys.Key1;
      & "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe" /Source:https://mayocustomimagessa.blob.core.windows.net/images /Dest:$dest /SourceKey:$srcKey /DestKey:$destKey /Pattern:rh7xazure.vhd
   }
   # custom VM image blob uri
   $sourceImageUri=$dest + '/rh7xazure.vhd'
   #$sourceImageUri =  "https://cliqrinfraexsa.blob.core.windows.net/images/rh7xazure.vhd"
}
else {
	# Which gallery image?
	if ($osName -eq "Windows" ) {
	   $pubName="MicrosoftWindowsServer"
	   $offerName="WindowsServer"
	   $skuName="2012-R2-Datacenter"
	}
	elseif ( $osName -eq "ubuntu") {  
	   $pubName="Canonical"
	   $offerName="UbuntuServer"
	   $skuName="14.04.3-LTS"
	}
	elseif ( $osName -eq "RHEL") {
	   $pubName="RedHat"
	   $offerName="RHEL"
	   $skuName="7.2"
	}  
	else {
	   "Unsupported Image...Nothing else to do"
	   Exit 1;
	}
 }  
# Network depends on whether public or Express Route
$nicName= "Nic1" + $vmName;
if ($network -eq "expressroute") {
   $vnetName="VnetExRT_NC_10.198.32";
   # Index for ExRouteSubnet is 0
   $subnetIndex=0;
   $vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName "Vnet_Linux_ExRT_NC_RG";
   $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id;
}
else {
   $vnetName = $prefix + "InfraNet";
   $vnetSubnetName = $prefix + "InfraSubnet";
   $subnetIndex=0;
   $vnetSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $vnetSubnetName -AddressPrefix 192.168.1.0/24
   $vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $locName -AddressPrefix 192.168.0.0/16 -Subnet $vnetSubnet
   $pip = New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
   $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id 
}




$vm=New-AzureRmVMConfig -vmName $vmName -VMSize $vmSize;

# Specify local administrator account, and then add the NIC
$cred=Get-Credential -Message "Type the name and password of the local administrator account."
if ( $osName -eq "Windows") {
   $vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent;
}
else {
   $vm=Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred;
}

$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id


# Specify the OS disk name and create the VM
$diskName="OSDisk"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
# $storageAcc=Get-AzureRmStorageAccount -ResourceGroupName mayocustomimagesrg -Name mayocustomimagessa;
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
if ($imageType -eq "custom") {
	if ( $osName -eq "Windows") {
	$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $sourceImageUri -Windows;
	}
	else {
	$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri $sourceImageUri -Linux;
	}
}	
else {
	$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
	if ( $osName -eq "Windows") {
	$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage;
	}
	else {
	$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage;
	}
}	
#####
# Create VM
#####
New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $vm 

#####