function ConvertFrom-RegEx {
    [CmdletBinding(
        DefaultParameterSetName="File"
    )]
    param (
        <# 
            Specifies the text to be parsed. Enter a variable that contains the text, or type a command or expression that gets the text.

            Using the InputObject parameter isn't the same as sending strings down the pipeline to `ConvertFrom-RegEx`.

            When you pipe more than one string to the `ConvertFrom-RegEx` cmdlet, it parses each string and returns an object (or objects) for each individual string.

            When you use the InputObject parameter to submit a collection of strings, `ConvertFrom-RegEx` treats the collection as a single combined string. `ConvertFrom-RegEx` returns object(s) if it finds the search text in any component string.
        #>
        [Parameter(
            ParameterSetName='InputObject', 
            Mandatory,
            ValueFromPipeline
        )]
        [AllowEmptyString()]
        [AllowNull()]
        [psobject]
        $InputObject,
        
        <#
            Specifies the text to find on each line. The pattern value is treated as a regular expression.

            To learn about regular expressions, see the `about_Regular_Expressions` PowerShell help document.
        #>
        [Parameter(
            Mandatory,
            Position=0
        )]
        [string[]]
        $Pattern,

        # A path to one or more files to parse. Wildcards are supported.
        [Parameter(
            ParameterSetName='File',
            Mandatory, 
            Position=1, 
            ValueFromPipelineByPropertyName
        )]
        [string[]]
        $Path,

        # Specifies the path to the files to be searched. The value of the LiteralPath parameter is used exactly as it's typed. No characters are interpreted as wildcards.
        [Parameter(
            ParameterSetName='LiteralFile', 
            Mandatory, 
            ValueFromPipelineByPropertyName
        )]
        [Alias('PSPath')]
        [string[]]
        $LiteralPath,
    
        # Indicates that the cmdlet matches should be case-sensitive. By default, matches aren't case-sensitive.
        [Parameter(
        )]
        [switch]
        $CaseSensitive,

        # Indicates that the cmdlet searches for more than one match in each line of text. Without this parameter, `ConvertFrom-RegEx` emits an object for only the first match in each line of text.
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