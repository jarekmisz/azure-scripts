$RGName = "MyResourceGroup";
$VMName = "MyTestVM";
#The KeyVault must have enabledForDiskEncryption property set on it
$VaultName= "MyKeyVault";
$KeyVault = Get-AzureRmKeyVault -VaultName $VaultName -ResourceGroupName $RGName;
$DiskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
$KeyVaultResourceId = $KeyVault.ResourceId;

# create Azure AD application and associate the certificate
$CertPath = "C:\certificates\examplecert.pfx";
$CertPassword = "Password";
$Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath, $CertPassword);
$KeyValue = [System.Convert]::ToBase64String($cert.GetRawCertData());
$AzureAdApplication = New-AzureRmADApplication -DisplayName "<Your Application Display Name>" -HomePage "<https://YourApplicationHomePage>" -IdentifierUris "<https://YouApplicationUri>" -KeyValue $KeyValue -KeyType AsymmetricX509Cert ;
$ServicePrincipal = New-AzureRmADServicePrincipal -ApplicationId $AzureAdApplication.ApplicationId;

$AADClientID = $AzureAdApplication.ApplicationId;
$aadClientCertThumbprint= $cert.Thumbprint;

#Upload pfx to KeyVault 
$KeyVaultSecretName = "MyAADCert';
$FileContentBytes = get-content $CertPath -Encoding Byte;
$FileContentEncoded = [System.Convert]::ToBase64String($fileContentBytes);
$JSONObject = @" { "data": "$filecontentencoded", "dataType" :"pfx", "password": "$CertPassword" } "@ ;
$JSONObjectBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonObject);
$JSONEncoded = [System.Convert]::ToBase64String($jsonObjectBytes);

$Secret = ConvertTo-SecureString -String $JSONEncoded -AsPlainText -Force;
Set-AzureKeyVaultSecret -VaultName $VaultName -Name $KeyVaultSecretName -SecretValue $Secret;
Set-AzureRmKeyVaultAccessPolicy -VaultName $VaultName -ResourceGroupName $RGName -EnabledForDeployment;

#deploy cert to VM
$CertUrl = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name $KeyVaultSecretName).Id
$SourceVaultId = (Get-AzureRmKeyVault -VaultName $VaultName -ResourceGroupName $RGName).ResourceId
$VM = Get-AzureRmVM -ResourceGroupName $RGName -Name $VMName 
$VM = Add-AzureRmVMSecret -VM $VM -SourceVaultId $SourceVaultId -CertificateStore "My" -CertificateUrl $CertUrl
Update-AzureRmVM -VM $VM -ResourceGroupName $RGName 

#Enable encryption on the virtual machine using Azure AD client ID and client cert thumbprint
Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $RGName -VMName $VMName -AadClientID $AADClientID -AadClientCertThumbprint $AADClientCertThumbprint -DiskEncryptionKeyVaultUrl $DiskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId ;