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
            }
        ) {
            $ActualValue = $InputString | ConvertFrom-RegEx -Pattern $Regex
            Assert-Equivalent -Actual $ActualValue -Expected $ExpectedValue -StrictOrder
        }
    }
}