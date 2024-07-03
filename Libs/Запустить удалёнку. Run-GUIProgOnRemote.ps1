# Запустить графическую программу на удалённом рабстоле

Param
(
    #это админские права. Не обязательно админ = кому включать прогу.
    [PSCredential] $credential = $(Get-Credential -Message 'Для использования данного скрипта требуется аутентификация.' -User ...),
    [string] $pcname = $(
        Write-Host 'Введите имя компа'
        Read-Host          
    ),
    [string] $username = $(    
        Write-Host 'Введите имя юзера, на рабстоле которого включать прогу'
        Read-Host
    ),
    [string] $password = $(    
        Write-Host 'Введите пароль'
        Read-Host
    ),
    [string] $program = $(    
        Write-Host 'Введите путь к программе, котрую включить. Относительно удалённого компа.'
        Read-Host
        #'C:\windows\system32\mspaint.exe'
    )
)

$psexecPath = "..."

function Get-IdSession([string] $username, [string] $pcname)
{    
    [string[]] $loginUsers = (Invoke-Command -ComputerName $pcname -ScriptBlock { query user } -Credential $credential)
    [string[]] $targetUsers = $loginUsers -match $username
    if ($targetUsers.count -ge 1 ) # >= 0
    {  
        Return (($targetUsers[0] -replace '\s\s+', ';') -split ';')[2].Trim()
    }
    else { Return '' }
}

[string] $userNoDomen = "$username".ToLower().Replace('...', '')
$idSession = (Get-IdSession -username "$userNoDomen" -pcname $pcname)
if ( -not ($idSession -eq ''))
{
    #Invoke{Start-Process} запустит прогу только в фоне. А на экран можно вывести только через psexec, предварительно найдя номер сессии, кому графон выводить.

    $argslist = "\\$pcname -u `"$($username)`" -p `"$($password)`" -d -h -i $idSession cmd.exe /c start $program"
    Start-Process -FilePath $psexecPath -ArgumentList $argslist -WindowStyle hidden    
}
else 
{ Write-Host "$username не залогинен. Отмена запуска программы." }
