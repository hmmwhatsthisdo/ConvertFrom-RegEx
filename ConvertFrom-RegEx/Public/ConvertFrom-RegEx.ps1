<#
.SYNOPSIS
    Extract structured objects from text using Regular Expression Capture Groups
.DESCRIPTION
    The `ConvertFrom-RegEx` cmdlet uses regular expression (RegEx) matching to search for text patterns in input strings and files. Using RegEx capture groups, text can be quickly extracted into PowerShell objects.
.NOTES
    For more information on capture groups in .NET Regular Expressions, see https://learn.microsoft.com/en-us/dotnet/standard/base-types/grouping-constructs-in-regular-expressions in the .NET documentation.
.EXAMPLE
    "A=1, B=2, C=3, C=4" | ConvertFrom-RegEx -Pattern "A=(?<A>\d+), B=(?<B>\d+), (?:C=(?<C>\d+)[,\s]*)+"

    A B C
    - - -
    1 2 {3, 4}
    
    Match the string "A=1, B=2, C=3, C=4" with the provided regular expression. Values from capture groups A and B are directly translated to their corresponding properties. As capture group C captures multiple times within a given match, its captures are returned as an array.
.EXAMPLE
    "A=1, B=2, C=3, C=4 | A=3, B=4, C=5, C=6" | ConvertFrom-RegEx -Pattern "A=(?<A>\d+), B=(?<B>\d+), (?:C=(?<C>\d+)[,\s]*)+" -AllMatches

    A B C
    - - -
    1 2 {3, 4}
    3 4 {5, 6}

    Match the string "A=1, B=2, C=3, C=4 | A=3, B=4, C=5, C=6" with the provided regular expression. As the -AllMatches parameter was specified, both the first and second halves of the string each result in their own object.
#>
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
        [ValidateScript({
            try {
                Assert-ValidCGRegex -Pattern $_ -ErrorAction Stop
            }
            catch {
                throw ([System.Management.Automation.ValidationMetadataException]::new($_.Exception.Message))
            }
            return $true
        })]
        [RegEx[]]
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


        # Pipelines should receive similar parameters under most circumstances, so load all of these into a hashtable and clone as necessary.
        $SelectStringParams = @{
            CaseSensitive = $CaseSensitive
            AllMatches = $AllMatches
        }
        If ($null -ne $Path) {
            $SelectStringParams["Path"] = $Path
        } elseif ($null -ne $LiteralPath) {
            $SelectStringParams["LiteralPath"] = $LiteralPath
        }

        # Build steppable pipelines for each provided regex
        $Pattern | ForEach-Object {
            $SelectStringSplat = $SelectStringParams + @{
                Pattern = $_
            }

            {Select-String @SelectStringSplat}.GetSteppablePipeline($myInvocation.CommandOrigin)
        } `
        | Set-Variable SelectStringPipelines

        # Open all of the pipelines
        $SelectStringPipelines | ForEach-Object {
            try {
                $_.Begin($PSCmdlet.MyInvocation.ExpectingInput)
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
            
            If (-not $pipelineRet) {
                # No match found
            } else {
                $pipelineRet `
                | ForEach-Object Matches `
                | ForEach-Object {
                    $_.Groups `
                    | Where-Object Name -ne 0 `
                    | ForEach-Object `
                        -Begin {
                            [Diagnostics.CodeAnalysis.SuppressMessage(
                                'PSUseDeclaredVarsMoreThanAssignments',
                                '',
                                Justification = 'Variable is used in downstream scope'
                            )]
                            $out = [ordered]@{}
                        } `
                        -Process {
                            $out[$_.Name] = $_.Captures.Value 
                        } `
                        -End {
                            Write-Output ([PSCustomObject]$out)
                        }
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