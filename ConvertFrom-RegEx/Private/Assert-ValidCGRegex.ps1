# Helper function to ensure RegExes have named capture groups
function Assert-ValidCGRegex {
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            Position=0
        )]
        [RegEx[]]$Pattern,
        
        [String[]]$RequiredGroupNames
    )
    
    begin {
        
    }
    
    process {
        $Pattern | % {
            $Groups = $_.GetGroupNames() | ? {$_ -ne '0'}

            If ($null -eq $Groups) {
                Write-Error -Message "Pattern '$_' does not contain any named capture groups."
            }
            
            $RequiredGroupNames | % {
                If ($null -eq ($Groups -like $_)) {
                    Write-Error "Pattern '$_' does not contain the required capture group '$_'."
                }
            }
        }
    }
    
    end {
        
    }
}