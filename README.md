# YorkRegionADModule
This module was designed for the York Region.

It contains convenient active directory data gathering functions. Due to policy, these functions only extract data from Active Directory and do not alter the directory in any way. If you are an Active Directory Database Manager at the York Region and ish to implement functions that cause changes, please email at simar.chawla@york.ca or simarchawla27@gmail.com.

The functions included in this module are:

Get-InactiveUsers

Get-PasswordExpiration (Output users who have not logged on in X amount of days)

Get-ContactInfo (Given a name of a user, display the user's basic contact information)

Get-UsersInDepartment (Input department to get its users)

Get-ChainOfCommand (recursively find the chain of command, so an input of Simar Chawla will return "My Manager's name"->"his manager"->"his manager"->...->"Chairman")

Get-OSList (List the OS’s that are in use)

Get-ComputersOnOS (Find the computers operating on the specified OS)

Get-ADGroupList (Output the names of the AD groups currently in the directory)

Get-ADGroupMemberNames (Output the users that belong to a specified AD group)

Get-UserMemberOf (Output the groups that a specified user belongs to)
