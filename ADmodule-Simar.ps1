###############################################################################################
# READ-ME
###############################################################################################
#
# Module Name: ADFunctions
# Author: Simar Chawla
# Company: Regional Municipality of York
# 
##################################################################################################################
# Module Description:
# This module contains convenient functions that automate many of the tedious tasks that are
# associated with gathering data from Active Directory. Due to policy, none of the functions alter
# the directory in any way. If you are an Active Directory Database Manager at the York Region and
# wish to implement functions that cause changes, please email at simar.chawla@york.ca or simarchawla27@gmail.com
##################################################################################################################
#PowerShell version details:
#PSVersion	4.0	
#WSManStackVersion	3.0	
#SerializationVersion	1.1.0.1	
#CLRVersion	4.0.30319.18063	
#BuildVersion	6.3.9600.16406	
#PSCompatibleVersions	{1.0, 2.0, 3.0, 4.0}	
#PSRemotingProtocolVersion	2.2	#>
##################################################################################################################


#Import AD module
Import-Module ActiveDirectory
Write-host "*****************************************************************************************"
Write-host "Welcome to the Active Directory module. This module has the following Functions: Get-InactiveUsers, Get-PasswordExpirationUsers, Get-ContactInfo, Get-UsersInDepartment, Get-ChainOfCommand"
Write-Host "-----------------------------------------------------------------------------------------"
Write-Host "Note: The functions Get-ContactInfo and Get-ChainOfCommand have name parameters. The names must be inputted as follows `"Lastname, Firstname`""
Write-Host "Example: Get-ContactInfo `"Chawla, Simar`" <-- Do not forget the space after Lastname,"
Write-Host "*****************************************************************************************"

#Used for Get-ChainOfCommand function
$parsetextfile = $env:UserProfile + "\pdftext.txt"
function ClearOrMake-files{
    param(
        [Parameter(Mandatory=$true)]
        $file
        )

    If (Test-Path $file){Clear-Content $file}
        else{New-item $file -type file}
}

ClearOrMake-files -file $parsetextfile

#Output users who have not logged on in X amount of days in grid-view
function Get-InactiveUsers{
    param(
    [Parameter(Mandatory=$true)] $Days,
    [switch] $service
    )
    $time = (Get-Date).AddDays(-($Days))

    #Service accounts included
    if ($service){
    Get-ADUser -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $true} -Properties LastLogonTimeStamp |
    select-object Name,@{Name=”Last Log-On Date”; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString(‘yyyy-MM-dd’)}}, @{Name = "Days Till Log On";
                     Expression = {((get-date) - [DateTime]::FromFileTime($_.lastLogonTimestamp)).days}} |Out-GridView}
    #Service Accounts not included
    else{
    Get-ADUser -Filter {LastLogonTimeStamp -lt $time -and enabled -eq $true -and Name -like "*,*"-and Description -notlike "*Service*"} -Properties LastLogonTimeStamp |
    select-object Name,@{Name=”Last Log-On Date”; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString(‘yyyy-MM-dd’)}}, @{Name = "Days Till Log On";
                     Expression = {((get-date) - [DateTime]::FromFileTime($_.lastLogonTimestamp)).days}} |Out-GridView}
}

#Output the users whose password is expiring in X amount of days
function Get-PasswordExpirationUsers{
    param(
    # Days password takes to expire
    [Parameter(Mandatory=$true)] $PassExpirationDays,
    #Show users whos passwords expire within $ExpirationRange days
    [Parameter(Mandatory=$true)] $ExpirationRange
    )

    #Arraylist that is bieng populated with users
    $output = New-Object -TypeName 'System.Collections.ArrayList';

 
    Foreach ($ADUsers in Get-ADuser -filter {(PassWordNeverExpires -eq "false") -and (Enabled -eq "True")}){ 
       # $adusers.SamAccountName
        $ADUser = Get-ADUser -Identity $ADUsers.SAMAccountName -Properties SamaccountName,DisplayName,Passwordlastset, Mail
 
        if($aduser.PasswordLastSet -ne $null){
        # Find expiration date
        $DayOfExpiration =  (get-date $aduser.passwordlastset).AddDays($PassExpirationDays) 
        # Find days left till expiration
        $DaysToExpire =  ((get-date $aduser.passwordlastset).AddDays($PassExpirationDays) - (get-date)).Days 
 
        #  This is where the $output variable is populated
        if (($DaysToExpire -le $ExpirationRange)-and ($DayofExpiration -ge (get-date))) {
        $object = New-Object PSObject -Property @{DisplayName=$ADUser.DisplayName; PasswordLastSet=$aduser.passwordlastset;'The date the password will expire on'=$DayOfExpiration ;DaysLeft=$DaysToExpire; EmailAddress=$ADUser.EmailAddress}
        [void]$output.add($object)
         }
       } 
    }
    #Show the $output in grid view
    $output|Out-GridView
}

#Given a name of a user, display the user's basic contact information
function Get-ContactInfo{
    param(
        [Parameter(Mandatory=$true)]
        $name
        )
    Get-ADUser -Filter "Name -like '*$name*'" -Properties *|Select-Object -Property Name,Mail,OfficePhone,Title,Description,Department,City, StreetAddress
}

#Output the names of all the members of a department
function Get-UsersInDepartment{
    #Array of the departments in the Active Directory
    $departArray = Get-ADUser -Filter * -Properties department | Select-Object -Property department |Sort-Object -Property department -unique
    
    #loop through each element in $departarray
    for($i = 0; $i -lt $departArray.Length; $i++){
    #Associate a number with each department and print it out for user to see
    $department = $departArray[$i]|out-string
    $department= $department.Substring(326, 64)
    write-host "($i) $department"
    }
    
    #Prompt user to choose a department by referencing the department number
    $departmentNum = Read-Host "Choose the number for the department, Ex: 42 for CHS - Public Health (Child and Family Health/Nursing Practice)"
    #Isolate the department name
    $temp = ((($departArray[$departmentNum]|out-string) -Split "`n")[3]).trim()
    #Output department members' names alphabetically
    Get-ADUser -Filter "department -like '$temp*' -and Description -notlike 'Service*' -and Name -like '*,*'"| select-object -Property Name |Sort-Object Name
}

#Recursively find the chain of command given a user
function Get-ChainOfCommand{
    param(
        [Parameter(Mandatory=$true)]
        $name
        )
    #Highest ranked member
    $chairman = "Emmerson, Wayne"

    #Find manager property of user
    $temp = (Get-ADUser -Filter "Name -like '*$name*'" -Properties *|Select-Object -Property Manager|out-string)

    #Used to make $temp an array, with the manager name occupying a line of its own
    #Converted to text and then back so that array is split every new line (Note after compeletion, could have also been done
    #with the Split method"
    ((($temp -split (",OU"))[0])|out-string).Replace("`n","").Replace("CN=","").Replace("\","") | out-file $parsetextfile

    #Array with one of its elements being the supervisor name
    $supName =  get-content $parsetextfile
    $temparraylen = $supname.Length

    #Find which line contains the supervisors name and mutate $supName variable to hold only the name
    for ($i=0; $i -lt $temparraylen; $i++){
         if ($supName[$i] -like "*,*"){
         $supName = ($supName)[$i]
         break
        }
     }

    #Base Case
    if ($supName -like $chairman){
    $supName
    return
    }

    else {
    $supName
    "v"
    #Recursive call
    Get-ChainOfCommand $supName
    }
}

#List the OS's currently in use
function Get-OSList{
    Get-ADComputer -Filter * -Properties OperatingSystem | Select OperatingSystem -unique | Sort OperatingSystem
}

#Find the computers operating on the specified OS
function Get-ComputersOnOS{
    param(
        [Parameter(Mandatory=$true)]
        $OS
        )
    Get-ADComputer -Filter "OperatingSystem -like'*$OS*'" -properties OperatingSystem,OperatingSystem| Select Name,Op* | format-list
}

#Output the names of the AD groups currently in the directory
function Get-ADGroupList{
    Get-ADGroup -Filter *|sort-object -Unique| Select-Object -Property Name| Out-GridView
}

#Output the users that belong to a specified AD group
function Get-ADGroupMembersNames{
    param(
        [Parameter(Mandatory=$true)]
        $ADGroup
        )
    Get-ADGroupMember "$ADGroup"|Select-object Name|Out-GridView
}

#Output the groups that a specified user belongs to
function Get-UserMemberOf{
    param(
        [Parameter(Mandatory=$true)]
        $name
        )
    #Get SAMAccountName
    $Identity = (Get-ADUser -Filter "Name -like '$name'" -Properties Name,SamAccountName).SamAccountName

    #Output names of the groups that user belongs to
    Get-ADPrincipalGroupMembership -Identity $Identity|select Name
} 


        
    