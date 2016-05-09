& "C:\Program Files (x86)\Windows Kits\8.1\bin\x86\makecert.exe" -sky exchange -r -n "CN=jmAzureEncrypt" -pe -a sha256 -len 2048 -ss My "jmAzureEncrypt.cer"
$CertPwd = Read-Host "What is the certificate's password?";
$CertPwd = ConvertTo-SecureString -String $CertPwd -Force -AsPlainText
$AzureCert = Get-ChildItem -Path Cert:\CurrentUser\My | where {$_.Subject -match "jmAzureEncrypt"}
# This commandlet does not exist on Windows 7
# Export-PfxCertificate -FilePath H:\.ssh\jmAzureEncrypt.pfx -Password $CertPwd -Cert $AzureCert
# Use the Certification manager from the Windows Kit instead
& "C:\Program Files (x86)\Windows Kits\8.1\bin\x86\certmgr.exe"