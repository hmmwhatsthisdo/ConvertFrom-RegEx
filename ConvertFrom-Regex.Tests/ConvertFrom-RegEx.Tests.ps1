Describe "ConvertFrom-RegEx" {

    BeforeAll {
        Import-Module .\ConvertFrom-RegEx -ErrorAction Stop -Force
        Import-Module Functional -DisableNameChecking -Force
    }

    Context "Output Comparison" {
        It "Should return expected value for `"<inputstring>`" (<regex>)" -ForEach @(
            @{
                InputString = "A=1, B=2, C=3"
                Regex = "A=(?<A>\d+), B=(?<B>\d+), (?:C=(?<C>\d+)[,\s]*)+"
                Expected = [PSCustomObject]@{
                    A = "1"
                    B = "2"
                    C = "3", "4"
                }
            }
        ) {
            ($InputString | ConvertFrom-RegEx -Pattern $Regex), $Expected | Test-Equality | Should -BeTrue
        }
    }
}