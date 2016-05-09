# Create a new Key Vault in the same region where the VM disk's need to be encrypted
New-AzureRmKeyVault -VaultName 'KeyVaultCUS' -ResourceGroupName 'KeyVaultCUSrg' -Location 'Central US'
 
# Enable Key Vault for Disk Encryption
Set-AzureRmKeyVaultAccessPolicy -VaultName 'KeyVaultCUS' -ResourceGroupName 'KeyVaultCUSrg' -EnabledForDiskEncryption

#Setup Azure Active Directory Application
$aadClientSecret = 'Somet0psecret!' # Client Secret
$azureAdApplication = New-AzureRmADApplication -DisplayName 'FDEKeyVault' -HomePage "http://www.microsoft.com " -IdentifierUris "https://FDEKeyVault" -Password $aadClientSecret
$servicePrincipal = New-AzureRmADServicePrincipal –ApplicationId $azureAdApplication.ApplicationId
  
# Set Key Vault access policy for the AAD application
$keyVaultName = ‘KeyVaultCUS’
$aadClientID = '82e71a67-a19c-403a-8ea6-825979123b7d' #From AAD Application
Set-AzureRmKeyVaultAccessPolicy -VaultName $keyVaultName -ServicePrincipalName $aadClientID -PermissionsToKeys all -PermissionsToSecrets all

# Initialize all variables
$rgName = ‘RHELFDE' ; # Resource Group which consists the VM attached disk to be encrypted
$vmName = ‘rhel72fde'; # Name of the VM whose attached disk is to be encrypted
$aadClientID = '82e71a67-a19c-403a-8ea6-825979123b7d '; # From AAD Application
$aadClientSecret = 'Somet0psecret!'; # Client Secret from AAD Application
$KeyVaultName = ‘KeyVaultCUS’;
$KeyVault = Get-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName KeyVaultCUSrg;
$diskEncryptionKeyVaultUrl = $KeyVault.VaultUri;
$KeyVaultResourceId = $KeyVault.ResourceId;
$volumeType='Data' ; # OS or Data disk, for RHEL its only Data Disk for now.
$sequenceVersion = '1'; # Increase this number for subsequent runs, if failure occurs.
# Optional Key Encryption Key
# $keyEncryptionKeyUrl =$null;
# $keyEncryptionAlgorithm ="RSA-OAEP"; 

# Run the Azure Disk Encryption Command
Set-AzureRmVMDiskEncryptionExtension -ResourceGroupName $rgname -VMName $vmName -AadClientID $aadClientID -AadClientSecret $aadClientSecret -DiskEncryptionKeyVaultUrl $diskEncryptionKeyVaultUrl -DiskEncryptionKeyVaultId $KeyVaultResourceId -VolumeType $volumeType -SequenceVersion $sequenceVersion 
 
