Clear-Host;

#Conexão com BD

function conexaoBD{

    Import-Module SimplySql;
    Get-Module SimplySql;

    $password=ConvertTo-SecureString "labmtec2022" -AsPlainText -Force;
    $cred=New-Object System.Management.Automation.PSCredential("root",$password);

    Open-MySqlConnection -server "127.0.0.1" -database "dto_keys" -Credential ($cred);

}

conexaoBD;

#Funcao que muda status para bloqueada
function setStateForBloqued{

    Write-Host "Chave BLOQUEADA: $idkey $keycontent";
  
    Invoke-SqlUpdate "CALL bloquedKey($idkey);";

    #$logUninstallKey = cscript slmgr.vbs /upk;
    #Write-Host "MENSAGEM DESINSTALACAO CHAVE: " $logUninstallKey;

}

#FUNCAO QUE MUDA STATUS PARA ATIVADA ATUALIZANDO SERIAL
function setStateForActived{

    Write-Host "ID Chave ativada: $idkey" -ForegroundColor Green`n;

    $array = @(wmic bios get serialnumber);
    $serialnumber = $array[2];

    $memoria = wmic computersystem get totalphysicalmemory
    $memoria0 = [math]::truncate($memoria[2] / 0.95GB)
    $totalMemoria = $memoria0 -as [int]

    Write-Host "Memória Total: $totalMemoria";

    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object Size, FreeSpace
    $ddc = [math]::truncate($disk.Size / 1GB)

    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='D:'" | Select-Object Size, FreeSpace
    $ddd = [math]::truncate($disk.Size / 1GB)

    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='E:'" | Select-Object Size, FreeSpace
    $dde = [math]::truncate($disk.Size / 1GB)

    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='F:'" | Select-Object Size, FreeSpace
    $ddf = [math]::truncate($disk.Size / 1GB)
        
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='G:'" | Select-Object Size, FreeSpace
    $ddg = [math]::truncate($disk.Size / 1GB)

    $totalDisco = $ddc + $ddd + $dde +$ddf + $ddg

    Write-Host "Disco Total: $totalDisco";

    Invoke-SqlUpdate "CALL activedKey($idkey,'$serialnumber',$totalDisco,$totalMemoria);";

    #deletaArquivos

}

#FUNCAO PARA PEGAR UMA NOVA CHAVE NO BANCO
function getKeyDb {
    
    $requisitionResult = Invoke-SqlQuery "CALL getKey('b9');";
    
    if ($requisitionResult -eq $null){

        Write-Host "Banco de Dados Vazio" -ForegroundColor yellow;
        break;

    }else{

        return $requisitionResult;
    
    }

}

#Função de ativação do sistema

function activation{

    #limpa os registros no DNS
    ipconfig /flushdns;

    Write-Host "------------------------------------Robô------------------------------------" -ForegroundColor DarkYellow`n;

    :loop
    for ($i = 0; $i -ne 1) {
    
        Write-Host "    Nova Chave    "-ForegroundColor blue;

        $chave = getKeyDb;
        $idkey = $chave[0];
        $keycont=$chave[1];

        Write-Host "ID Key: $idkey";
        Write-Host "Product Key: $keycont";

        #Código de instalação da chave na máquina. 
        $logVbsIpk = cscript slmgr.vbs /ipk $keycont;
        Write-Host "MENSAGEM DE INSTALACAO: $logVbsIpk" -ForegroundColor Yellow`n;

        #Estrutura de condição if que verifica se a chave do windows foi instalado com sucesso.
        if($logVbsIpk | sls "instalada com êxito."){

            $i = 1, (Write-Host "Valid Product Key"-ForegroundColor green);

        }else {

            $i= 0,(Write-Host "Invalid Product Key"`n -ForegroundColor red);

        }

        $logVbsAto = cscript slmgr.vbs /ato;
        Write-Host "MENSAGEM DE ATIVACAO: $logVbsAto" -ForegroundColor Yellow`n;

        #Estrutura que verifica se a máquina está ativada.
        for ($i = 0; $i -ne 1) {
            
            $Activation = (Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object PartialProductKey | Select-Object -First 1).LicenseStatus;

            if ($Activation -eq 1) {
                
                setStateForActived;
                $i = 1;
                Write-Host "O Windows está ativado." -ForegroundColor green`n;

            } else {

                setStateForBloqued;
                Write-Host "O Windows não está ativado." -ForegroundColor red`n;
                break :loop;

            }
        
        }

    }

}

activation;

Close-SqlConnection;