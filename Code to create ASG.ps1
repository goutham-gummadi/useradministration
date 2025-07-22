$Groups= @("ASG_LC_DM_DataBricks_PRD_DataWarehouse_r","ASG_LC_DM_DataBricks_PRD_DataWarehouse_rm")
$Owner="6ef88a96-d57e-4ae6-a8ab-7168ae01158b"
foreach($group in $Groups){
    if($group -like "PRD"){
        $Env="PRD"
    }
    elseif($group -like "STG"){
        $Env="STG"
    }
    elseif($group -like "_NP_"){
        $Env="NP"
    }
    $description= "This group gives Read access to Databricks data warehouse in $Env environment"

    New-MgGroup -DisplayName $Group -MailNickname $Group -Description $description -SecurityEnabled:$true -MailEnabled:$false
    Start-Sleep -Seconds 3
    $Info=Get-MgGroup -Filter "displayname eq '$Group'"
    New-MgGroupOwner -GroupId $Info.Id -DirectoryObjectId $Owner
}