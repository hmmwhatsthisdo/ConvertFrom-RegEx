function ConvertFrom-RegEx {
    [CmdletBinding(
        DefaultParameterSetName="File"
    )]
    param (
        [Parameter(
            ParameterSetName='InputObject', 
            Mandatory,
            ValueFromPipeline
        )]
        [AllowEmptyString()]
        [AllowNull()]
        [psobject]
        $InputObject,
        
        [Parameter(
            Mandatory,
            Position=0
        )]
        [string[]]
        $Pattern,

        [Parameter(
            ParameterSetName='File',
            Mandatory, 
            Position=1, 
            ValueFromPipelineByPropertyName
        )]
        [string[]]
        $Path,

        [Parameter(
            ParameterSetName='LiteralFile', 
            Mandatory, 
            ValueFromPipelineByPropertyName
        )]
        [Alias('PSPath')]
        [string[]]
        $LiteralPath,
    
        [Parameter(
        )]
        [switch]
        $CaseSensitive,

        [Parameter(
        )]
        [switch]
        $AllMatches
    )
    
    begin {
        # Build steppable pipelines for each provided regex
        $Pattern | ForEach-Object {
            $SelectStringSplat = @{
                Pattern = $_
                CaseSensitive = $CaseSensitive
                AllMatches = $AllMatches
            }
            If ($null -ne $Path) {
                $SelectStringSplat["Path"] = $Path
            } elseif ($null -ne $LiteralPath) {
                $SelectStringSplat["LiteralPath"] = $LiteralPath
            }

            {Select-String @SelectStringSplat}.GetSteppablePipeline($myInvocation.CommandOrigin)
        } `
        | Set-Variable SelectStringPipelines

        # Open all of the pipelines
        $SelectStringPipelines | ForEach-Object {
            try {
                $_.Begin($true)
            } catch {
                throw
            }
        } -ErrorAction Stop
    }
    
    process {
        $_InputObject = $_

        $SelectStringPipelines | ForEach-Object {
            try {
                $pipelineRet = $_.Process($_InputObject)
            }
            catch {
                throw    
            }
            
            If ($null -eq $pipelineRet) {
                # No match found
            } else {
                $pipelineRet `
                | ForEach-Object Matches `
                | ForEach-Object Groups `
                | Where-Object Name -ne 0 `
                | ForEach-Object `
                    -Begin {$out = [ordered]@{}} `
                    -Process {
                        $out[$_.Name] = $_.Captures.Value 
                    } `
                    -End {
                        Write-Output ([PSCustomObject]$out)
                    }
            }
        } -ErrorAction Stop `
        | Set-Variable "pipelineOutputs"


        If ($null -eq $pipelineOutputs) {
            # no matches found for any lines
        } else {
            Write-Output $pipelineOutputs
        }


    }
    
    end {
        $SelectStringPipelines | ForEach-Object {
            try {
                $_.End()
            }
            catch {
                throw
            }
        } -ErrorAction Stop
    }
}