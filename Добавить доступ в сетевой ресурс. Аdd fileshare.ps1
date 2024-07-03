Write-Host "Добавлялка групп ... пользователю ver. 1"

$path = Read-Host -Prompt 'Введи путь до шары (полностью, с X:\, без кавычек)'
$path = "..." + $path.Substring(2) #diskname is not accepted by get-acl, move it back to a fileshare
$readOnly = Read-Host -Prompt 'Только для чтения? y\n'
$UserToAdd = Read-Host -Prompt 'Имя пользователя AD'
if ($readOnlyFlag -eq "y")
{
    $ReadOnly = "R"#,"REPORTERS"
}
else
{
    $ReadOnly = "RW"#,"MANAGERS"
};

$pathFinder = "*Sh_*" + $ReadOnly
$pathFinder = Get-Acl $path | ForEach-Object { $_.Access.IdentityReference.value -like $pathFinder } 
Write-Host "Выбрана группа" $pathFinder
$pathFinder = 'Name -like "' + ($pathFinder.substring(9))  + '"' 

$GroupSelected = Get-ADGroup -Filter $pathFinder -properties info,description
if ($GroupSelected.info -like "?*")
{
    Write-Host "Для добавления требуется согласование ответственного."
    $GroupSelected.info
    $isAllowed = Read-Host -Prompt "Согласование есть? y/n"
    Write-Host "`n"
    if ($isAllowed -eq 'y')
    {
        Write-Host "Добавляю..."
        Add-ADGroupMember -Identity $GroupSelected -Members $UserToAdd
    }
    else
    {
        Write-Host "Нужно согласование"
    };
}
else
{
    Write-Host "Добавляю..."
    Add-ADGroupMember -Identity $GroupSelected -Members $UserToAdd
}
