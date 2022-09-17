Describe "ConvertFrom-RegEx" {

    BeforeAll {
        Import-Module .\ConvertFrom-RegEx -ErrorAction Stop -Force
        Import-Module Assert -Force
    }

    Context "Output Comparison" {
        It "Should return expected value for `"<inputstring>`" (<regex>)" -ForEach @(
            @{
                InputString = "A=1, B=2, C=3"
                Regex = "A=(?<A>\d+), B=(?<B>\d+), (?:C=(?<C>\d+)[,\s]*)+"
                ExpectedValue = [PSCustomObject]@{
                    A = "1"
                    B = "2"
                    C = "3"
                }
                AdditionalParameters = @{}
            }
            @{
                InputString = "A=1, B=2, C=3, C=4"
                Regex = "A=(?<A>\d+), B=(?<B>\d+), (?:C=(?<C>\d+)[,\s]*)+"
                ExpectedValue = [PSCustomObject]@{
                    A = "1"
                    B = "2"
                    C = "3", "4"
                }
                AdditionalParameters = @{}
            }
            @{
                InputString = "A=1, B=2, C=3, C=4 | A=3, B=4, C=5, C=6"
                Regex = "A=(?<A>\d+), B=(?<B>\d+), (?:C=(?<C>\d+)[,\s]*)+"
                ExpectedValue = [PSCustomObject]@{
                    A = "1"
                    B = "2"
                    C = "3", "4"
                }
                AdditionalParameters = @{}
            }
            @{
                InputString = "A=1, B=2, C=3, C=4 | A=3, B=4, C=5, C=6"
                Regex = "A=(?<A>\d+), B=(?<B>\d+), (?:C=(?<C>\d+)[,\s]*)+"
                ExpectedValue = @(
                    [PSCustomObject]@{
                        A = "1"
                        B = "2"
                        C = "3", "4"
                    },
                    [PSCustomObject]@{
                        A = "3"
                        B = "4"
                        C = "5", "6"
                    }
                )
                AdditionalParameters = @{
                    AllMatches = $true
                }
            }
        ) {
            $ActualValue = $InputString | ConvertFrom-RegEx -Pattern $Regex @AdditionalParameters
            Assert-Equivalent -Actual $ActualValue -Expected $ExpectedValue -StrictOrder
        }
    }
}