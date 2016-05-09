#login-AzureRmAccount -SubscriptionId 3796604e-350d-40ea-8d8d-aca340420104

$locName="northcentralus";
$rgName="cliqrinfrarg"
$nicName="Nic1CLLPCQR001A"

$rule1 = New-AzureRmNetworkSecurityRuleConfig -Name ssh-rule -Description "Allow SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 22
    

$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName -Location westus -Name "NSG-JumBox" `
    -SecurityRules $rule1   
    
$nic=Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName 

