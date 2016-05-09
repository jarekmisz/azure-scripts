Login-AzureRmAccount -SubscriptionId f6c0cb91-aaca-4ff3-9bd9-4be01af16a8b

# Set to Windows, RHEL, or ubuntu
$osName = "Windows"
# Set to expressroute if it's needed, otherwise a public vnet will be created
$network = "public"
# Increase this number for subsequent runs, if failure occurs.
$sequenceVersion = "1"; 
# Since RG doesn't contain all the objects, need prefix for cleanup
$prefix = "aac";
$vmName = $prefix + "jmencryptvm" + $sequenceVersion;
#$vmRgName= $prefix + "JmSecureVmRg";
$rgName = $prefix + "jmkeyvaultrg";
$vmRgName = $rgName;
#The KeyVault must have enabledForDiskEncryption property set on it
$VaultName= $prefix + "jmkeyvault";
$AAName = $VaultName + "app";
$locName="centralus";


# Which image?
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

New-AzureRmResourceGroup -Name $vmRgName -Location $locName;

$saName=$vmName + "sa";
$saType="Standard_LRS";
New-AzureRmStorageAccount -Name $saName -ResourceGroupName $vmRgName -Type $saType -Location $locName;

# Network depends on whether public or Express Route
$nicName= "Nic1" + $vmName;
if ($network -eq "expressroute") {
   $vnetName="ExRouteVnet";
   # Index for ExRouteSubnet is 0
   $subnetIndex=0;
   $vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName "ChicagoER_RG";
   $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $vmRgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id;
}
else {
   $vnetName = $vmName + "Net";
   $vnetSubnetName = $vmName + "Subnet";
   $subnetIndex=0;
   $vnetSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $vnetSubnetName -AddressPrefix 192.168.1.0/24
   $vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $locName -AddressPrefix 192.168.0.0/16 -Subnet $vnetSubnet
   $pip = New-AzureRmPublicIpAddress -Name $nicName -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
   $nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id -PublicIpAddressId $pip.Id
}



$vmSize="Standard_D1_v2";
$vm=New-AzureRmVMConfig -vmName $vmName -VMSize $vmSize;

# Specify local administrator account, and then add the NIC
$cred=Get-Credential -Message "Type the name and password of the local administrator account."
if ( $osName -eq "Windows") {
   $vm=Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent;
}
else {
   $vm=Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred;
}
$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# Specify data disk 
# !!! This section added Apr 6, 2016 by jarek
$dataDiskSize=1
$dataDiskLabel="EncryptedDataDisk1"
$dataDiskName="DataDisk01"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName
$vhdURI=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $dataDiskName  + ".vhd"
Add-AzureRmVMDataDisk -VM $vm -Name $dataDiskLabel -DiskSizeInGB $dataDiskSize -VhdUri $vhdURI  -CreateOption empty
# !!! End of addition

# Specify the OS disk name and create the VM
$diskName="OSDisk"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $vmRgName -Name $saName
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
#####
# Create VM
#####
New-AzureRmVM -ResourceGroupName $vmRgName -Location $locName -VM $vm 

#####
# Encryption Flow starts here
#####

# Create a new Key Vault in the same region where the VM disk's need to be encrypted
$KeyVault = New-AzureRmKeyVault -VaultName $VaultName -ResourceGroupName $rgName -Location $locName;
# $KeyVault = Get-AzureRmKeyVault -VaultName $VaultName -ResourceGroupName $rgName;
# Enable Key Vault for Disk Encryption
Set-AzureRmKeyVaultAccessPolicy -VaultName $VaultName -ResourceGroupName $rgName -EnabledForDiskEncryption;
$DiskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
$KeyVaultResourceId = $KeyVault.ResourceId;

# create AAD application and associate the certificate
$CertPath = "h:\.ssh\jmAzureEncrypt.pfx";
$CertPassword = Read-Host "What is the certificate's password?";
$Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath, $CertPassword);
# Prod version
# $CertPassword = Read-Host 'What is the certificate password?'-AsSecureString;
# $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath, [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($CertPassword)));

$KeyValue = [System.Convert]::ToBase64String($cert.GetRawCertData());
$AAIdUris = "http://" + $AAName + ".mayo.edu" 
$AzureAdApplication = New-AzureRmADApplication -DisplayName $AAName -HomePage $AAIdUris -IdentifierUris $AAIdUris -KeyValue $KeyValue -KeyType AsymmetricX509Cert ;
$ServicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $AzureAdApplication.ApplicationId;
$AADClientID = $AzureAdApplication.ApplicationId;
$aadClientCertThumbprint= $cert.Thumbprint;

#Upload pfx to KeyVault 
$KeyVaultSecretName = "jmAADCert";
$FileContentBytes = get-content $CertPath -Encoding Byte;
$FileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes);
$jsonObject = @"
{"data" : "$filecontentencoded",
"dataType" :"pfx",
"password": "$CertPassword"
}
"@;

$JSONObjectBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonObject);
$JSONEncoded = [System.Convert]::ToBase64String($jsonObjectBytes);
$Secret = ConvertTo-SecureString -String $JSONEncoded -AsPlainText -Force;
Set-AzureKeyVaultSecret -VaultName $VaultName -Name $KeyVaultSecretName -SecretValue $Secret;
Set-AzureRmKeyVaultAccessPolicy -VaultName $VaultName -ResourceGroupName $rgName -EnabledForDeployment;

#deploy cert to VM
$CertUrl = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name $KeyVaultSecretName).Id
#Need to Fix the CertUrl!!!
$CertUrl = $CertUrl -replace ":443"
$SourceVaultId = (Get-AzureRmKeyVault -VaultName $VaultName -ResourceGroupName $rgName).ResourceId
$VM = Get-AzureRmVM -ResourceGroupName $vmRgName -Name $vmName
if ( $osName -eq "Windows") {
   $VM = Add-AzureRmVMSecret -VM $VM -SourceVaultId $SourceVaultId -CertificateStore "My" -CertificateUrl $CertUrl
}
else {
   $VM = Add-AzureRmVMSecret -VM $VM -SourceVaultId $SourceVaultId -CertificateUrl $CertUrl
}
Update-AzureRmVM -VM $VM -ResourceGroupName $vmRgName 

#Enable encryption on the VM using AAD client ID and client cert thumbprint
# Encrypt OSDisk - does not work as of Apr 6, 2016 
# Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $vmRgName -vmName $vmName -AadClientID $AADClientID -AadClientCertThumbprint $AADClientCertThumbprint -DiskEncryptionKeyVaultUrl $DiskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId;
$volumeType="All" ; # OS and Data disk, 
# $volumeType="Data" ; # for Linux its only Data Disk for now.
Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $vmRgName -vmName $vmName -AadClientID $AADClientID -AadClientCertThumbprint $AADClientCertThumbprint -DiskEncryptionKeyVaultUrl $DiskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId -VolumeType $volumeType -SequenceVersion $sequenceVersion -Verbose;
