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

        It "Should parse file <inputfile> with regex <regexfile>" -ForEach @(
            @{
                InputFile = ".\ConvertFrom-Regex.Tests\SyslogTest.log"
                RegExFile = ".\ConvertFrom-Regex.Tests\SyslogRegex.rgx"
                ExpectedValue = @(
                    [PSCustomObject]@{
                        month = "Sep"
                        day = "18"
                        time = "00:00:30"
                        hostname = "exampleserver"
                        daemon = "systemd"
                        PID = "1"
                        message = "logrotate.service: Succeeded."
                    },
                    [PSCustomObject]@{
                        month = "Sep"
                        day = "18"
                        time = "00:00:30"
                        hostname = "exampleserver"
                        daemon = "systemd"
                        PID = "1"
                        message = "Finished Rotate log files."
                    },
                    [PSCustomObject]@{
                        month = "Sep"
                        day = "18"
                        time = "00:00:31"
                        hostname = "exampleserver"
                        daemon = "systemd"
                        PID = "1"
                        message = "man-db.service: Succeeded."
                    },
                    [PSCustomObject]@{
                        month = "Sep"
                        day = "18"
                        time = "00:00:31"
                        hostname = "exampleserver"
                        daemon = "systemd"
                        PID = "1"
                        message = "Finished Daily man-db regeneration."
                    },
                    [PSCustomObject]@{
                        month = "Sep"
                        day = "18"
                        time = "00:10:36"
                        hostname = "exampleserver"
                        daemon = "python3"
                        PID = "357033"
                        message = "2022-09-18T00:10:36.925728Z INFO ExtHandler ExtHandler [HEARTBEAT] Agent WALinuxAgent-2.8.0.11 is running as the goal state agent [DEBUG HeartbeatCounter: 915;HeartbeatId: 00000000-0000-0000-0000-000000000000;DroppedPackets: 0;UpdateGSErrors: 0;AutoUpdate: 1]"
                    }
                )
                AdditionalParameters = @{}
            }
        ) {
            $ActualValue = Get-Item -Path $InputFile | ConvertFrom-RegEx -Pattern (Get-Content $RegExFile -Raw) @AdditionalParameters
            Assert-Equivalent -Actual $ActualValue -Expected $ExpectedValue -StrictOrder
        }
    }
}