#Create Array of objs
$objs = @()

#Create new objects in the array for each type of certificate store
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPublisher","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("ClientAuthIssuer","LocalMachine")
$objs += New-Object System.Security.Cryptography.x509Certificates.x509Store("Remote Desktop","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("Root","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedDevices","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("CA","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("Windows Live ID Token Issuer","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("REQUEST","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("AuthRoot","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("AAD Token Issuer","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("FlightRoot","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("SmartCardRoot","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("TrustedPeople","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("AddressBook","LocalMachine")
$objs += New-Object System.Security.Cryptography.x509Certificates.x509Store("My","LocalMachine")
$objs += New-Object System.Security.Cryptography.X509Certificates.X509Store("CertificateAuthority","LocalMachine")
$objs += New-Object System.Security.Cryptography.x509Certificates.x509Store("Trust","LocalMachine")
$objs += New-Object System.Security.Cryptography.x509Certificates.x509Store("Homegroup Machine Certificates","LocalMachine")
$objs += New-Object System.Security.Cryptography.x509Certificates.x509Store("SMS","LocalMachine")

#For each store object in the array, open them all for read/write, look at the certificates and where expiration is less than today remove the certificate
ForEach ($obj in $objs)
{
    $obj.Open("ReadWrite")

    ForEach ($cert in $obj.certificates)
    {
      if ($cert.NotAfter -lt $(Get-Date))
      {
       $obj.Remove($cert)
      }
    }

    $obj.Close()
}
