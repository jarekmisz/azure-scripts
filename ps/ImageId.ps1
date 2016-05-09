$locName="centralus"
Get-AzureRmVMImagePublisher -Location $locName | Select PublisherName
$pubName="RedHat"
Get-AzureRmVMImageOffer -Location $locName -Publisher $pubName | Select Offer
$offerName="RHEL"
Get-AzureRmVMImageSku -Location $locName -Publisher $pubName -Offer $offerName | Select Skus