# Import active directory module for running AD cmdlets
Import-Module activedirectory

  
#Store the data from ADUsers.csv in the $ADUsers variable
$ADUsers = Import-csv "C:\powershell project\bulk_users1.csv"

#Loop through each row containing user details in the CSV file 
foreach ($User in $ADUsers)
{
	#Read user data from each field in each row and assign the data to a variable as below
		
	$Username 	= $User.username
	$Password 	= $User.password
	$Firstname 	= $User.firstname
	$Lastname 	= $User.lastname
	$OU 		= $User.ou #This field refers to the OU the user account is to be created in
    $email      = $User.email
    $streetaddress = $User.streetaddress
    $city       = $User.city
    #$zipcode    = $User.zipcode
    $state      = $User.state
    #$country    = $User.country
    $telephone  = $User.telephone
    $jobtitle   = $User.jobtitle
    $company    = $User.company
    $department = $User.department
    $Password = $User.Password


	#Check to see if the user already exists in AD
	if (Get-ADUser -F {SamAccountName -eq $Username})
	{
		 #If user does exist, give a warning
		 Write-Warning "A user account with username $Username already exist in Active Directory."
	}
	else
	{
		#User does not exist then proceed to create the new user account
		
        #Account will be created in the OU provided by the $OU variable read from the CSV file
		New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@team3.local" `
            -Name "$Firstname $Lastname" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -DisplayName "$Lastname, $Firstname" `
            -Path $OU `
            -City $city `
            -Company $company `
            -State $state `
            -StreetAddress $streetaddress `
            -OfficePhone $telephone `
            -EmailAddress $email `
            -Title $jobtitle `
            -Department $department `
            -AccountPassword (convertto-securestring $Password -AsPlainText -Force) -ChangePasswordAtLogon $True
    
        New-Item "\\dc\c\parent-directory\$Username" -Type Directory
        $sharepath = "\\dc\c\parent-directory\$Username\"
        New-SmbShare -Name $Username -Path $sharepath -FullAccess "team3\Adminstrator", "team3\domain admins" -ReadAccess "team3\$Username"
        
            if ((Get-PSSnapin -Name MailEnable.Provision.Command -ErrorAction SilentlyContinue) -eq $null )
            {
                Add-PsSnapin MailEnable.Provision.Command
            }
    
        New-MailEnableMailbox -Mailbox "$Username" -Domain "team3.local" -Password "$Password" -Right "USER"


        $From = "MVonDauber@team3.local"
        $To = "$Username@team3.local"
        $Subject = "Welcome to team3!"
        $Body = "Hello and welcome to our company! 
        Your login information is- 
        USERNAME:$Username
        PASSWORD: $Password
        If you have any questions, you can reply to this email or visit me in my office."
        $SMTPServer = "team3.local"
        $SMTPPort = "587"

        $MailPassword = ConvertTo-SecureString "Cita300" -AsPlainText -Force
        $MailCredentials = New-Object System.Management.Automation.PSCredential($From, $MailPassword)
        
        Send-MailMessage -From $From -To $To  -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort -Credential $MailCredentials

        $email1 = "*****USRNAME*****"
        $email2 = $Username
        $email1 >> userlist.txt
        $email2 >> userlist.txt

        $email3 = "*****PASSOWRD*****"
        $email4 = $Password
        $email3 >> userlist.txt
        $email4 >> userlist.txt

        Send-MailMessage -From "mvondauber@team3.local" -To "mvondauber@team3.local" -Subject "Updated User List" -Body "The user list has been updated." -Attachments userlist.txt -SmtpServer $SMTPServer -Port $SMTPPort -Credential $MailCredentials
    }
    Send-MailMessage -From "mvondauber@team3.local" -To "mvondauber@team3.local" -Subject "Updated User List" -Body "The user list has been updated." -Attachments userlist.txt -SmtpServer $SMTPServer -Port $SMTPPort -Credential $MailCredentials
}
Get-ADUser -Filter * -Properties created |Select-Object name , created |Sort-Object created -Descending 
