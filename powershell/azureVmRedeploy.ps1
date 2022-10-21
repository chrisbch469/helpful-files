#Reference

    #Get-AzSubscription 
    #Set-AzContext 
    #Get-AzResourceGroup
    #Get-azresource -name XXX

#Input

Connect-AzAccount
    
$sub= Read-host "Subscription of vm to redploy"

Write-host "Setting Subscription"

set-azcontext $sub

$vmname = Read-Host "Vm to Redploy"
$rg = Get-Azvm -name $vmName | foreach {$_.ResourceGroupName}

$loc = Get-Azvm -resourcegroupname $rg -name $vmName | foreach {$_.Location}

$orgDisk= Get-AzDisk -resourcegroupname $($rg) | where-object {$_.ManagedBy -like "*$($vm)*"} | foreach{$_.Name}
$id= Get-AzDisk -resourcegroupname $($rg) | where-object {$_.ManagedBy -like "*$($vm)*"} | foreach{$_.Id}
$vm = Get-AzVM -ResourceGroupName $rg -Name $($vmName) | foreach{$_.Name}



$snapName= "$($vmName)Snap$(Get-Date -format yyMMdd)"
$nicName = "$($vm)nic"
$vnet=get-azvirtualNetwork -resourcegroupname "azuRgForti" -Name "azuFortiFwNet" |foreach {$_.Subnets[5].Id}
$newVmName = "$($vm)Clone"



#Process


#get-azvm -resourcegroupname $($rg) -Name "$($vm)" | foreach{$_.name}

Write-host "Stopping VM"

stop-azvm -ResourceGroupName $($rg) -name "$($vm)" -Force

#Get-AzDisk -resourcegroupname $($rg) | where-object {$_.ManagedBy -like "*$($vm)*"} | foreach{$_.Name}

#get-azdisk -resourcegroupname $($rg) -name $orgDisk



#Output

$snapshot =  New-AzSnapshotConfig -SourceResourceId $id -Location $loc -CreateOption copy

Write-host "Creating Vm Snapshot"

New-AzSnapshot -ResourceGroupName $($rg) -Snapshot $($snapshot) -SnapshotName $snapName

#Get-AzSnapshot -ResourceGroupName $($rg) | Where-Object {$_.Name -Match "$snapName"}

$snapId=  Get-AzSnapshot -ResourceGroupName $($rg) | Where-Object {$_.Name -Match "$snapName"} | foreach{$_.Id}

$destRG = "$($rg)Clone"

Write-host "Creating Resource Group"

New-AzResourceGroup -Location 'eastus' -Name $destRG

Write-host "Creating Vm Disk Clone"

New-Azdisk -resourcegroupname "$($rg)Clone" -DiskName "$($vmName)Clone" (new-azdiskconfig -location $loc -CreateOption copy -sourceuri $snapId) 




#get-azvirtualNetwork -resourcegroupname "azuRgForti" -Name "azufortifwnet" | foreach{$_.Subnets}

 
 
#Get-AzVirtualNetworkSubnetConfig -Name "intsub" -VirtualNetwork "azufortifwnet" 

$osDisk=get-azdisk -ResourceGroupName "$($rg)Clone" -DiskName "$($vmName)Clone"
$nic = New-AzNetworkInterface -Name "$nicName" -ResourceGroupName "$($rg)Clone" -Location $loc -SubnetId $vnet
$vmConfig = New-AzVMConfig -VMName $newVmName -VMSize "Standard_B1s" #Prompt for vm size
$vmNew = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
$vmNew = Set-AzVMPlan -Name "cis-centos7-l1" -Product "cis-centos-7-v2-1-1-l1" -Publisher "center-for-internet-security-inc" -VM $vmnew  #Grab VM plan information for automation 
$vmnew = Set-AzVMBootDiagnostic -VM $vmnew -Disable 
$vmnew = Set-AzVMOSDisk -VM $vmnew -ManagedDiskId $osdisk.Id  -StorageAccountType Standard_LRS `
    -CreateOption Attach  -Linux 
    
Write-host "Creating Vm"

New-AzVm -ResourceGroupName $destRG   -Location 'eastus' -VM $vmNew