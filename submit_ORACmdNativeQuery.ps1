# =======================================================
#
#    submit_ORACmdNativeQuery.ps1
#             
# =======================================================
#
# NAME: submit_ORACmdNativeQuery.ps1
# AUTHOR: TRICLIN J (Real)
# DATE: 18/01/2019
#
# ROLE: Execute ORACLE with SQLPlus Query and generate ORA out file
# VERSION: 2.0
# KEYWORDS:
# COMMENTS:  
#           
# =======================================================

# =======================================================
#    Bloc Declaration ORA
# =======================================================
Param
(
        # Declaration du serveur ORA
        [Parameter(Mandatory=$true)][string]$argORAServeur,

        # Declaration de la DB
        [Parameter(Mandatory=$true)][string]$argORADB,

        # Declaration ORA Query
        [Parameter(Mandatory=$true)][string]$argORAQueryFilePath,

        # Declaration ORA User
        [Parameter(Mandatory=$true)][string]$argORAProtectedUser,

        # Declaration ORA Pwd
        [Parameter(Mandatory=$true)][string]$argORAProtectedPwd,

        # Declaration chemin de sortie ORA
        [Parameter(Mandatory=$true)][string]$argORAOutFilePath,

        # Declaration du nom du rapport
        [Parameter(Mandatory=$true)][string]$argORAReportFileName,

        # Declaration Extension File
        [Parameter(Mandatory=$true)][string]$argORAColSeparator,

        # Declaration ORA Query Parameters
        [Parameter(Mandatory=$false)][string]$argORAQueryParams
)

# =======================================================
#    Bloc Fonctions
# =======================================================

function TimeStampFunction
{

    #[DateTime]$getDate = (Get-Date -Format "yyyy/MM/dd HH:mm:ss.fff")
    [DateTime]$getDate = Get-Date

    #le format du string attend un int pour l'option 'f'
    #[string]$varTS = "{0:D4}" -f [int]"string"
    # ou [string]$varTS = "{0:D4}" -f int/digit
    [string]$yearTS = "{0:D4}" -f $($getDate.Year)
    [string]$monthTS = "{0:D2}" -f $($getDate.Month)
    [string]$dayTS = "{0:D2}" -f $($getDate.Day)

    #return "YYYYMMDD"
    return "${yearTS}${monthTS}${dayTS}"
} 

# ======================================
#    Bloc du PROGRAMME MAIN
# ======================================

function main
{
    Param
    (
        # Declaration du serveur ORA
        [Parameter(Mandatory=$true)][string]$argORAServeur,

        # Declaration de la DB
        [Parameter(Mandatory=$true)][string]$argORADB,

        # Declaration ORA Query
        [Parameter(Mandatory=$true)][string]$argORAQueryFilePath,

        # Declaration ORA User
        [Parameter(Mandatory=$true)][string]$argORAProtectedUser,

        # Declaration ORA Pwd
        [Parameter(Mandatory=$true)][string]$argORAProtectedPwd,

        # Declaration chemin de sortie ORA
        [Parameter(Mandatory=$true)][string]$argORAOutFilePath,

        # Declaration du nom du rapport
        [Parameter(Mandatory=$true)][string]$argORAReportFileName,

        # Declaration Extension File
        [Parameter(Mandatory=$true)][string]$argORAColSeparator,

        # Declaration ORA Query Parameters
        [Parameter(Mandatory=$false)][string]$argORAQueryParams
    )

    Write-Host "======================================"
    Write-Host "||                                  ||" 
    Write-Host "||                                  ||" 
    Write-Host "||          LANCEMENT SCRIPT        ||" 
    Write-Host "||    submit_ORACmdNativeQuery.ps1  ||"
    Write-Host "||                                  ||" 
    Write-Host "||                                  ||"
    Write-Host "======================================"

    Write-Host ""
    Write-Host ""
    Write-Host " Recuperation et definition du parametrage en cours..."

    $ORAServeur = $argORAServeur
    $ORADB = $argORADB
    $ORAQueryFilepath = $argORAQueryFilePath

    $ORAProtectedUserFilePath = $argORAProtectedUserFilePath

    $ORAProtectedUser = $argORAProtectedUser 
    $ORAProtectedPwd = $argORAProtectedPwd 
     
    $ORAOutFilePath = $argORAOutFilePath
    $ORAReportFileName = $argORAReportFileName
    $ORAColSeparator = $argORAColSeparator
    $ORAFileExtension = ""

    if($argORAQueryParams.Length -eq 0)
    {
        $ORAQueryParams = ""
    }
    else
    {
        $ORAQueryParams = $argORAQueryParams
    }

    $ORACMDFullPathList = @("C:\Oracle\Oracle0\Product\1210216\BIN\sqlplus.exe",`
                            "C:\Oracle\product\12.1.0\BIN\sqlplus.exe")
    $ORACMDFullPathOK = ""

    Write-Host " =>Fin de recuperation du parametrage OK"

    
    Write-Host ""
    Write-Host " Verifcation existence commande SQLCMD.exe en cours..."
    

    $flagORACMDexists = 0

    Foreach($ORACMD in $ORACMDFullPathList)
    {
        Write-Host "$ORACMD"

        if(Test-Path ($ORACMD))
        {
            $ORACMDFullPathOK = $ORACMD
            $flagORACMDexists = 1
            break
        }
    
    }

    if($flagORACMDexists -eq 1)
    {
        Write-Host " =>SQLPLUS.exe trouve: ${ORACMDFullPathOK}"
    }
    else
    {
        Write-Host " =>Aucun ORACMD.exe sur la machine"
        Write-Host ""
        Write-Host "--------------------------------"
        Write-Host " TRT TERMINE EN ERREUR -KOKOKO  "
        Write-Host "--------------------------------"

        Exit 1
    }
    Write-Host ""
    Write-Host " Verification de l'existence du sepatateur de colonnes en cours..."

    if($ORAColSeparator.Length -gt 0 )
    {
        Write-Host " =>Separarteur trouve: '$ORAColSeparator'"

        switch($ORAColSeparator)
        {
            ","{$ORAFileExtension=".csv"}
            ";"{$ORAFileExtension=".dsv"}
            default{$ORAFileExtension=".csv"; $ORAColSeparator="," }
        }

    }else
    {
        Write-Host " =>Aucun separateur defini"
        Write-Host " =>Analyser Erreur"
        Write-Host ""
        Write-Host "--------------------------------"
        Write-Host " TRT TERMINE EN ERREUR -KOKOKO  "
        Write-Host "--------------------------------"

        Exit 1
    }


    Write-Host ""
    Write-Host " Verification de l'existence de la requete '${ORAQueryFilepath}' en cours..."
    if(-not (Test-Path $ORAQueryFilepath))
    {
        Write-Host " =>Fichier Requete SQL inexistant"
        Write-Host " =>Analyser Erreur"
        Write-Host ""
        Write-Host "--------------------------------"
        Write-Host " TRT TERMINE EN ERREUR -KOKOKO  "
        Write-Host "--------------------------------"

        Exit 1
    
    }
    else
    {
        Write-Host " =>Fichier Requete SQL trouve -OK"

    }

    Write-Host ""
    Write-Host " Verification du repertoire de sortie '$ORAOutFilePath' en cours..."

    if(-not (Test-Path $ORAOutFilePath))
    {
        Write-Host " =>Le repertoire n'existe pas"
        Write-Host " =>Analyser Erreur"
        Write-Host ""
        Write-Host "--------------------------------"
        Write-Host " TRT TERMINE EN ERREUR -KOKOKO  "
        Write-Host "--------------------------------"

        Exit 1
    
    }
    else
    {
        Write-Host " =>Le repertoire existe -OK"
    }

    Write-Host ""
    Write-Host " Verification cohérence du nom du rapport en cours..."

    if($ORAReportFileName.Length -eq 0)
    {
        Write-Host " =>Aucun nom de rapport defini"
        Write-Host " =>Analyser Erreur"
        Write-Host ""
        Write-Host "--------------------------------"
        Write-Host " TRT TERMINE EN ERREUR -KOKOKO  "
        Write-Host "--------------------------------"

        Exit 1
    }
    else
    {
        Write-Host " =>Nom du rapport OK"
    }
    Write-Host ""
    Write-Host ""

    $ORAOutFileNameFullPath = $ORAOutFilePath + "\" + $ORAReportFileName + "_$(TimeStampFunction)" + $ORAFileExtension

    Write-Host " Lancement de la requete - Rappel parametrage:"
    Write-Host "----------------------------------------------"
    Write-Host "ORACLE Serveur        : '${ORAServeur}'"
    Write-Host "ORACLE DB             : '${ORADB}'"
    Write-Host "ORACLE User           : '${ORAProtectedUser}'"
    Write-Host "ORACLE Query File     : '${ORAQueryFilepath}'"
    Write-Host "ORACLE OutFileFullPath: '${ORAOutFileNameFullPath}'"
    Write-Host "SQLPLUS.exe FullPath  : '${ORACMDFullPathOK}'"
    Write-Host "ORACLE Scripts Params : '${ORAOutFileNameFullPath} ${ORAColSeparator} ${ORAQueryParams}'"
    Write-Host ""
    Write-Host " Lancement requete SQL en cours..."
    Write-Host "=> ${ORACMDFullPathOK} -S ORAProtectedUser/ORAProtectedPwd@${ORADB} @${ORAQueryFilepath} $ORAOutFileNameFullPath $ORAColSeparator $ORAQueryParams"
    Write-Host ""

    &$ORACMDFullPathOK -S "${ORAProtectedUser}/${argORAProtectedPwd}@${ORADB}" @$ORAQueryFilepath $ORAOutFileNameFullPath $ORAColSeparator $ORAQueryParams
    #&$ORACMDFullPathOK "-S CLV61IN1/CLV_61_IN1@ORLSOL08 @'D:\solife-DB\Scripts\Extract_ErrorPolicies_Generic_Fees_batch.sql'"

    if($?)
    {
        Write-Host " =>Recuperation Data et Generation du fichier OK"

    }
    else
    {
        Write-Host " =>Erreur durant la generation"
        Write-Host " =>Analyser Erreur"
        Write-Host ""
        Write-Host "--------------------------------"
        Write-Host " TRT TERMINE EN ERREUR -KOKOKO  "
        Write-Host "--------------------------------"

        Exit 1
    }

    Write-Host ""
    Write-Host "------------------------------"
    Write-Host " TRT TERMINE AVEC SUCCES -OK  "
    Write-Host "------------------------------"


    Exit 0

}


# ======================================
#    Execution du PROGRAMME
# ======================================

#    Arg1:serveur ORACLE, Arg2: Declaration de la DB, Arg3: SQL Query File, Arg4: ORA User, Arg5: ORA Pwd, Arg6: chemin de sortie, Arg7: Nom du rapport, Arg8: separateur Colonne, Arg9: Argument Query ORA
main $argORAServeur $argORADB $argORAQueryFilePath $argORAProtectedUser $argORAProtectedPwd $argORAOutFilePath $argORAReportFileName $argORAColSeparator $argORAQueryParams