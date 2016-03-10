$vmName = '1jmsecurevm4';
#$vmRgName= '1jmSecureVmRg';
$rgName = "1jmkeyvaultrg";
$vmRgName = $rgName;
#The KeyVault must have enabledForDiskEncryption property set on it
$VaultName= "jmkeyvault";
$locName="centralus";

#New-AzureRmResourceGroup -Name $vmRgName -Location $locName;

$saName=$vmName + "sa";
$saType="Standard_LRS";
New-AzureRmStorageAccount -Name $saName -ResourceGroupName $vmRgName –Type $saType -Location $locName;

$vnetName="TestVnet";
# Index for Subnet-1 is 0
$subnetIndex=0;
$vnet=Get-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName "ChicagoER_RG";
$nicName= "Nic1" + $vmName;
$nic = New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $vmRgName -Location $locName -SubnetId $vnet.Subnets[$subnetIndex].Id;


$vmSize="Standard_D1_v2";
$vm=New-AzureRmVMConfig -vmName $vmName -VMSize $vmSize;

# Specify the image and local administrator account, and then add the NIC
$pubName="Canonical"
$offerName="UbuntuServer"
$skuName="14.04.3-LTS"

$cred=Get-Credential -Message "Type the name and password of the local administrator account."
$vm=Set-AzureRmVMOperatingSystem -VM $vm -Linux -ComputerName $vmName -Credential $cred;
$vm=Set-AzureRmVMSourceImage -VM $vm -PublisherName $pubName -Offer $offerName -Skus $skuName -Version "latest"
$vm=Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

# Specify the OS disk name and create the VM
$diskName="OSDisk"
$storageAcc=Get-AzureRmStorageAccount -ResourceGroupName $vmRgName -Name $saName
$osDiskUri=$storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/" + $vmName + $diskName  + ".vhd"
$vm=Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption fromImage
New-AzureRmVM -ResourceGroupName $vmRgName -Location $locName -VM $vm -Debug



$KeyVault = Get-AzureRmKeyVault -VaultName $VaultName -ResourceGroupName $rgName;
$DiskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
$KeyVaultResourceId = $KeyVault.ResourceId;

# create AAD application and associate the certificate
$CertPath = "h:\.ssh\jmAzureCert.pfx";
$CertPassword = Read-Host 'What is the certificate password?';
$Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath, $CertPassword);
# Prod version
# $CertPassword = Read-Host 'What is the certificate password?'-AsSecureString;
# $Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath, [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($CertPassword)));

$KeyValue = [System.Convert]::ToBase64String($cert.GetRawCertData());
$AzureAdApplication = New-AzureRmADApplication -DisplayName "jmkeyvaultapp4" -HomePage "http://jmkeyvaultapp4.mayo.edu" -IdentifierUris "http://jmkeyvaultapp4.mayo.edu" -KeyValue $KeyValue -KeyType AsymmetricX509Cert ;
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
Set-AzureRmKeyVaultAccessPolicy -VaultName $VaultName -ResourceGroupName $rgName -EnabledForDiskEncryption;

#deploy cert to VM
$CertUrl = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name $KeyVaultSecretName).Id
#Need to Fix the CertUrl!!!
$SourceVaultId = (Get-AzureRmKeyVault -VaultName $VaultName -ResourceGroupName $rgName).ResourceId
$VM = Get-AzureRmVM -ResourceGroupName $vmRgName -Name $vmName 
# $VM = Add-AzureRmVMSecret -VM $VM -SourceVaultId $SourceVaultId -CertificateStore "My" -CertificateUrl $CertUrl
$VM = Add-AzureRmVMSecret -VM $VM -SourceVaultId $SourceVaultId -CertificateUrl $CertUrl
Update-AzureRmVM -VM $VM -ResourceGroupName $vmRgName 

#Enable encryption on the VM using AAD client ID and client cert thumbprint
Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $vmRgName -vmName $vmName -AadClientID $AADClientID -AadClientCertThumbprint $AADClientCertThumbprint -DiskEncryptionKeyVaultUrl $DiskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId;
