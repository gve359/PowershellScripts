<#
    .SYNOPSIS
        Восстанавливает на магазинах 1С,УТМ,подключается удалёнкой.
    .DESCRIPTION
        Первым запуском нужно подключиться на магаз удалённо, чтобы вслепую не прервать возможную выгрузку на кассы, или может там кто-то чинит 1С, или сервер только-что запустился и сессия ... там не запущена.
        Вторым запуском уже делать задуманное.
        
        Данные по магазинам берутся из списка в ...\Libs\Get-Shops.lib.ps1

        Установка
        Чтобы скрипт запускал удалёнку(rms), нужно добавить путь к папке rms в системную переменную PATH. Например:
        $oldpath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).path
        $newpath = "$oldpath" + ';C:\install\rms.viewer.portable\'
        Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newpath
    .PARAMETER credential
        Запускать только от учётки ....
    .PARAMETER shopsNums
        Список номеров магазинов через запятую.
    .PARAMETER commands
        Список команд через запятую.                       
        1 = tv = Connect-RemoteDesktop
        2 = ru = Restart-UTM
        3 = ra = Restart-1CAgents
        4 = cc = Clear-Cache
        5 = ro = Restart-Obmen
        6 = rf = Restart-Full1C = ra,cc,ro
    .EXAMPLE
        Пример запуска со всеми параметрами:
        .\Rise-Shops.ps1 -credential $creds -shopsNums 100,101 -commands cc,ro
    
        Параметры можно не вводить. Сам спросит что не указано.
        .\Rise-Shops.ps1
#>

Param
(
    [PSCredential] $credential = $(Get-Credential -Message 'Для использования данного скрипта требуется аутентификация.' -User ...),
    [int[]] $shopsNums = $(
        Write-Host 'Введите список номеров магазинов через запятую'
        (Read-Host) -split ','
    ),
    [String[]] $commands = $(
        Write-Host 'Введите список команд через запятую'
        Write-Host '1 = tv = Connect-RemoteDesktop'
        Write-Host '2 = ru = Restart-UTM'
        Write-Host '3 = ra = Restart-1CAgents'
        Write-Host '4 = cc = Clear-Cache'
        Write-Host '5 = ro = Restart-Obmen'
        Write-Host '6 = rf = Restart-Full1C = ra,cc,ro'
        (Read-Host) -split ','
    )
)

[string] $scriptsTechSup_Folder = "..."
<#Import#> . ($scriptsTechSup_Folder + 'Libs\Get-Shops.lib.ps1')


function Connect-RemoteDesktop( [string] $pcname )
{
	Write-Host 'Удалёнка подключается'
    Start-Process rutview.exe -ArgumentList "-create -Name:$pcname -host:$pcname -fullcontrol"
}

function Restart-Obmen( [Shop] $shop, [PSCredential] $credential )
{
    Write-Host 'Перезапуск 1С ОбменЦО'

    if ($shop.os -eq 'windows')
    {	        
        Invoke-Command -ComputerName $shop.pcname -ScriptBlock { Stop-Process -Name 1cv8* -Force } -Credential $credential -asjob | Out-Null
        Start-Sleep -Seconds 3        
        & ($scriptsTechSup_Folder + 'Libs\Run-GUIProgOnRemote.ps1') -credential $credential -pc $shop.pcname -username '...' -password '...' -program '...\ОбменЦО.lnk'
        
        Write-Host 'Запущено, сработает через 30 секунд. Возможно нужно нажать "Да" в окне UAC.'
    }
    else 
    { Write-Host 'Linux пока не поддерживается' -ForegroundColor Red }
}

function Restart-UTM( [string] $pcname, [PSCredential] $credential )
{
    #lin сервера поддерживаются, потомучто utm всегда на вендокомпах
    Write-Host 'Перезапуск УТМ ЕГАИС'

	Invoke-Command -ComputerName $pcname -ScriptBlock { Stop-Service  transport } -Credential $credential -asjob | Out-Null
	Start-Sleep -Seconds 10
	Invoke-Command -ComputerName $pcname -ScriptBlock { Start-Service transport } -Credential $credential -asjob | Out-Null
    
	Write-Host 'Готово'
}

function Restart-ObmenAgents( [Shop] $shop, [PSCredential] $credential )
{
    Write-Host 'Перезапуск 1С агентов'

    if ($shop.os -eq 'windows')
    {
        Invoke-Command -ComputerName $shop.pcname -ScriptBlock { Stop-Process -Name 1cv8* -Force } -Credential $credential -asjob | Out-Null
        Start-Sleep -Seconds 3
        Invoke-Command -ComputerName $shop.pcname -ScriptBlock { Stop-Service *1C* } -Credential $credential  | Out-Null
        Start-Sleep -Seconds 5
        Invoke-Command -ComputerName $shop.pcname -ScriptBlock { Stop-Process -Name rphost -Force } -Credential $credential -asjob | Out-Null
        Invoke-Command -ComputerName $shop.pcname -ScriptBlock { Stop-Process -Name rmngr  -Force } -Credential $credential -asjob | Out-Null
        Invoke-Command -ComputerName $shop.pcname -ScriptBlock { Stop-Process -Name ragent -Force } -Credential $credential -asjob | Out-Null
        Start-Sleep -Seconds 2
        Invoke-Command -ComputerName $shop.pcname -ScriptBlock { Start-Service *1C* } -Credential $credential  | Out-Null
        
        Write-Host 'Готово'
    }
    else 
    { Write-Host 'Linux пока не поддерживается' -ForegroundColor Red
	  # sudo systemctl stop srv1cv83.service
	  # sudo systemctl stop srv1cv83@8.3.20.1710.service
	  # sudo systemctl stop system-srv1cv83.slice
	}
}

function Clear-Cache( [string] $pcname, [PSCredential] $credential )
{
    if ($shop.os -eq 'windows')
    {
        Write-Host 'Очистка кэша 1С'
        & ($scriptsTechSup_Folder + 'Clear-Cache.ps1') -pc $pcname -username '...' -invokeMode -credential $credential
        Write-Host 'Готово'
    }    
    else { Write-Host 'Linux пока не поддерживается' -ForegroundColor Red }
}

<#
function Restart-Postgress. # Просто перезапускать postgres - опасно. Надо сначала проверить что нет ресинхронизации raid дисков. 
Примерно так:
echo 'list volume' > C:\temp\diskpartCommands.txt
diskpart /s C:\temp\diskpartCommands.txt > C:\temp\diskpartOut.txt 
Invoke-Command -ComputerName $Computer -ScriptBlock { diskpart /s C:\temp\bp\command.txt > C:\temp\bp\out.txt } -Credential $Credential
#>



# Начало скрипта
$shopsNums | foreach { if ( -not ($allShops.ContainsKey( $_ ))) { Write-Host "Магазина $_ нет в официальном списке"  -ForegroundColor Red } }
[Shop[]] $shops = Get-Shops -nums $shopsNums


foreach ($shop in $shops)
{
	Write-Host $shop.pcname

	foreach ($command in $commands)
	{
		switch -regex ($command)
		{
			'(^1$)|(^tv$)|(^Connect-RemoteDesktop$)' { Connect-RemoteDesktop -pcname $shop.pcname }
			'(^2$)|(^ru$)|(^Restart-UTM$)'           { Restart-UTM -pcname $shop.pcname -credential $credential }                                                        
			'(^3$)|(^ra$)|(^Restart-ObmenAgents$)'   { Restart-ObmenAgents -shop $shop -credential $credential }
			'(^4$)|(^cc$)|(^Clear-Cache$)'           { Clear-Cache -pcname $shop.pcname -credential $credential }
			'(^5$)|(^ro$)|(^Restart-Obmen$)'         { Restart-Obmen -shop $shop -credential $credential }
			'(^6$)|(^rf$)|(^Restart-Full1C$)'        { Restart-ObmenAgents -shop $shop -credential $credential
													   Clear-Cache -pcname $shop.pcname -credential $credential
													   Restart-Obmen -shop $shop -credential $credential
													 } 
		}        
	}
    Write-Host ''
}
Write-Host "Всё сделано, босс!"
