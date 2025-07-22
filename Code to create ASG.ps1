$Groups= @("")
$Owner=""
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
