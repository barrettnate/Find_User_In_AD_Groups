#Written by: Nate Barrett
#03/12/2024



# Requires the Active Directory module
Import-Module ActiveDirectory

# Function to prompt for usernames
function Get-Usernames {
    $usernames = @()
    do {
        $username = Read-Host "Enter a username (leave empty and press Enter when done)"
        if ($username -ne '') {
            $usernames += $username
        }
    } while ($username -ne '')
    return $usernames
}

# Function to prompt for an OU and convert it to uppercase
function Get-OU {
    $partOU = Read-Host "Enter Facility Location (e.g. USTP)"
    $ou = "OU=Groups,OU=" + $partOU + ",OU=United States,DC=us,DC=am,DC=win,DC=colpal,DC=com"
    return $ou.ToUpper()
}


# Function to get all groups in the specified OU and its sub-OUs, excluding certain groups
function Get-GroupsInOU {
    param (
        [string]$ouDistinguishedName,
        [string[]]$excludedGroups
    )

    $allGroups = Get-ADGroup -Filter * -SearchBase $ouDistinguishedName -ErrorAction SilentlyContinue
    $filteredGroups = $allGroups | Where-Object { $excludedGroups -notcontains $_.Name }
    return $filteredGroups
}

# Function to check if a user is a member of a group
function Is-MemberOfGroup {
    param (
        [string]$username,
        [string]$groupName
    )

    # Get the user object with the 'memberOf' attribute
    $user = Get-ADUser -Identity $username -Properties memberOf -ErrorAction SilentlyContinue

    # Check if the user's 'memberOf' attribute contains the group's distinguished name
    $group = Get-ADGroup -Identity $groupName -ErrorAction SilentlyContinue
    if ($group -and $user.memberOf -contains $group.DistinguishedName) {
        return $true
    } else {
        return $false
    }
}

# Define the list of groups to exclude
#$excludedGroups = @('USTP_LanAdmin', 'USTP_DBA-Server AccessU', 'USTP_48HrsU', 'USTP_ETU')

# Get usernames from the user
$usernames = Get-Usernames

# Get OU from the user and convert it to uppercase
$ou = Get-OU

# Get all groups in the specified OU, excluding the specified groups
$groups = Get-GroupsInOU -ouDistinguishedName $ou #-excludedGroups $excludedGroups

# Check each user against each group in the OU
foreach ($user in $usernames) {
    $memberOfGroups = @()
    foreach ($group in $groups) {
        if (Is-MemberOfGroup -username $user -groupName $group.Name) {
            $memberOfGroups += $group.Name
        }
    }

    if ($memberOfGroups.Count -gt 0) {
        Write-Host "User $user is a member of the following groups in the OU $ou":"`n"
        Write-host $($memberOfGroups -join ', ')"`n" -ForegroundColor Green
    } else {
        Write-Host "User $user is NOT a member of any groups in the OU $ou."
    }
}