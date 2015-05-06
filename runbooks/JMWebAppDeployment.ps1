workflow JMWebAppDeployment
{
    
    param(
        
        [parameter(Mandatory=$true)]
        [String]
        $subscriptionName="Infrastructure Sandbox",
        
        [parameter(Mandatory=$true)]
        [String]
        $deploymentPrefix="jamlnx",
        
        [parameter(Mandatory=$true)]
        [Int]
        $numberOfVMs=2,
        
        [parameter(Mandatory=$true)]
        [String]
        $vmInstanceSize="Standard_D1",
        
        [parameter(Mandatory=$true)]
        [String]
        $location="South Central US"
        
      
    )
   $ErrorActionPreference = "Stop"
   # Get Azure credential for authenticating to Azure subscriptions
   $cred = Get-AutomationPSCredential -Name "miszczyk.jaroslaw@mayo.edu"

   # Get vmAdmin credential for admin access inside each VM
   $vmAdmin = Get-AutomationPSCredential -Name 'AzureAdmin'
   
   # Set common variable values for provisioning each VM
   $storageName = $deploymentPrefix + 'stor01'
   $vmServiceName = $deploymentPrefix +'svc01'
   $affinityGroupName = $deploymentPrefix + 'ag01'
   $availabilitySetName = $deploymentPrefix + 'asn01'
   #$vNetName = $deploymentPrefix + 'net01'
   #$subnetName ='Subnet-1'
   #$dscArchive = 'AADSCWebConfig.ps1.zip'
   #$dscConfigName = 'WebSiteConfig'
   
   $vmImage = Get-AutomationVariable -Name 'WebImageName' # base image
   $vmAdmin = Get-AutomationVariable -Name 'LinuxUser'
   $vmPassword = Get-AutomationVariable -Name 'LinuxPassword'
   
  for ($i=1; $i -le $numberOfVMs; $i++)
   {
        "Interation: $i"
        Checkpoint-Workflow
        "Please be patient while I connect to your Azure subscription..."       
        # Connect to Azure subscription
        Add-AzureAccount -Credential $cred

        Select-AzureSubscription `
          -SubscriptionName $subscriptionName | Write-Verbose
       
        # Set current Azure Storage Account
        Set-AzureSubscription `
          -SubscriptionName $subscriptionName `
          -CurrentStorageAccountName $storageName

        # Provision VM
        InlineScript {
     
             # Assign unique, random name
             $stamp = get-date -Format "FFFFFFF"
             $vmName = $Using:deploymentPrefix + 'vm' + $stamp

      
             # Specify VM name, image and size
             $vm = New-AzureVMConfig `
               -Name $vmName `
               -ImageName $Using:vmImage `
               -InstanceSize $Using:vmInstanceSize
     
             # Specify VM local admin and domain join creds
             $vm = Add-AzureProvisioningConfig -Linux `
                                                -VM $vm `
                                                -LinuxUser $Using:vmAdmin `
                                                -password $Using:vmPassword
         
             # Specify load-balanced firewall endpoint for HTTP
             $vm = Add-AzureEndpoint `
               -VM $vm `
               -Name 'WebHTTP' `
               -LBSetName 'LBWebHTTP' `
               -DefaultProbe `
               -Protocol tcp `
               -LocalPort 8080 `
               -PublicPort 8080
     
             # Specify VNet Subnet for VM
             #$vm = Set-AzureSubnet `
             #  -VM $vm `
             #  -SubnetNames $Using:subnetName
         
             # Specify HA Availability Set for VM
             $vm = Set-AzureAvailabilitySet `
               -VM $vm `
               -AvailabilitySetName $Using:availabilitySetName

             #Specify the Location of the script and the command to execute
             $PublicConfiguration = '{"fileUris":["https://raw.github.com/jarekmisz/azure-scripts/master/linux/create-web-site.sh"], "commandToExecute": "/bin/bash ./create-web-site.sh" }' 

             #Deploy the extension to the VM, pick up the latest version of the extension
             $ExtensionName = 'CustomScriptForLinux'  
             $Publisher = 'Microsoft.OSTCExtensions'  
             $Version = '1.*' 
             
             $vm = Set-AzureVMExtension -VM $vm -ExtensionName $ExtensionName -Publisher $Publisher -Version $Version -PublicConfiguration $PublicConfiguration -Verbose
                          
             # Provision new VM with specified configuration
             New-AzureVM `
               -ServiceName $Using:vmServiceName `
               -VMs $vm `
               -Location $Using:location `
               -ServiceDescription "JAM Web Services using python" `
               -Verbose `
               -WaitForBoot
                
         }

    }

}
