# Set the credentialsWrite-Host "Убивалка-запускалка 1С и УТМ ЕГАИС ver. 1.2"
$Credential = Get-Credential -Message "Для использования данного скрипта требуется аутентификация." -User ...

$psexecPath = "...\PsExec64.exe"

$isapp = Read-Host -Prompt "k$Computer-app? 1 == да"
if ($isapp -eq 1)
{
    $Computer = $Computer.ToString() + "-app"
}

$s1C = Read-Host -Prompt '1C убивать? 1 == да'
$egais = Read-Host -Prompt 'УТМ ЕГАИС перезапускать? 1 == да'
$s1CHASP = Read-Host -Prompt 'Проблема с лицензиями (большое жёлтое окно)? 1 == да'
$s1CStart = Read-Host -Prompt '1C запускать? 1 == да'

foreach ($i in $Computer)
{
    #EGAIS
    if ($egais -eq 1)
    {
        Invoke-Command -ComputerName k$i -ScriptBlock { kill -name daemon -Force } -Credential $Credential  | Out-Null
        Invoke-Command -ComputerName k$i -ScriptBlock { start-service Transport* } -Credential $Credential  -asjob | Out-Null
        Write-Host "УТМ ЕГАИС убит и перезапущен"
        
    }
    #1C
    if ($s1C -eq 1)
    {
        Invoke-Command -ComputerName k$i -ScriptBlock { kill -name 1cv8 -Force } -Credential $Credential -asjob | Out-Null
        Invoke-Command -ComputerName k$i -ScriptBlock { kill -name rphost -Force } -Credential $Credential -asjob | Out-Null
        Invoke-Command -ComputerName k$i -ScriptBlock { kill -name rmngr -Force } -Credential $Credential -asjob | Out-Null
        Invoke-Command -ComputerName k$i -ScriptBlock { restart-service LM } -Credential $Credential  | Out-Null
        Invoke-Command -ComputerName k$i -ScriptBlock { restart-service 1C* } -Credential $Credential -asjob | Out-Null
        Write-Host "1C убит и Агент перезапущен"
        cmd /c "D:\rms.viewer.portable\rutview.exe" -create -name:"k$i" -host:k$i -fullcontrol
    }
    if ($s1CHASP -eq 1)
    {
        Invoke-Command -ComputerName k$i -ScriptBlock { Copy-Item -Path "..." -Destination "..." -Force -PassThru } -Credential $Credential
        cmd.exe /c $psexecPath -id -u "..." -p "..." -h -w C:\ \\k$Computer cmd.exe /c ...\restart.bat
        Invoke-Command -ComputerName k$i -ScriptBlock { restart-service 1C* } -Credential $Credential -asjob | Out-Null
    }
    #clear server cache
    if ($s1Ccache -eq 1)
    {
        Invoke-Command -ComputerName k$i -ScriptBlock { Stop-Service -name 1C*  } -Credential $Credential 
        #Get path. It's GUID, so take a chance, pick first one you see
        $LogGUIDpath = Invoke-Command -ComputerName k$i -ScriptBlock { Return (Get-ChildItem "C:\Program Files (x86)\1cv8\srvinfo\reg_1541\").Name[0] }
        $LogGUIDpath = "C:\Program Files (x86)\1cv8\srvinfo\reg_1541\" + $LogGUIDpath + "\1Cv8Log"
        #
        Invoke-Command -ComputerName k$i -ArgumentList ($LogGUIDpath+ "\*") -ScriptBlock { Remove-Item $args[0] } -Credential $Credential 
        Invoke-Command -ComputerName k$i -ArgumentList $LogGUIDpath -ScriptBlock { New-Item -Path $args[0] -Name "\1Cv8.lgf" -ItemType "file" } -Credential $Credential
        Invoke-Command -ComputerName k$i -ScriptBlock { Start-Service -name 1C*  } -Credential $Credential
    }
    # start 1C
    if ($s1CStart -eq 1)
    {
        $winver = Invoke-Command -ComputerName k$i -ScriptBlock { [System.Environment]::OSVersion.Version.Major } -Credential $Credential
        if ($winver -eq 5) #if winver == 5 (winxp)
        {
           cmd.exe /c $psexecPath -id -u "..." -p "..." -h -w C:\ \\k$i cmd.exe /c ...\ОбменЦО.lnk | Out-Null

            Write-Host "1С запущена"
        }
        else
        {
            cmd.exe /c $psexecPath -id -u "..." -p "..." -h -w C:\ \\k$i cmd.exe /c ...\Desktop\Sms.lnk -h | Out-Null
            #Start-Sleep -s 60 #sleep for 60s, wait for UAC prompt to pass
            cmd.exe /c $psexecPath -id -u "..." -p "..." -h -w C:\ \\k$i cmd.exe /c ...\Desktop\ОбменЦО.lnk -h | Out-Null
            Write-Host "1С запущена. Возможно нужно нажать 'Да' в окне UAC."
        }
    }

    Write-Host "Всё сделано, босс!"
}
