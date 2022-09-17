Describe "Static Tests" {
    Context "Module Layout" {
        Context "Function Files" {
            BeforeDiscovery {

                $FunctionCache = @{}

                ("Private", "Public") | % {

                    $FunctionCache.$_ = @(
                        Get-ChildItem ".\ConvertFrom-RegEx\$_" -Filter *.ps1 -ErrorAction SilentlyContinue`
                        | % {
                            @{
                                Name = $_.BaseName
                                Path = $_.FullName
                            }
                        }
                    )

                }


            }

            Context "<name>" -ForEach (@($FunctionCache.Public + $FunctionCache.Private)) {

                Context "Syntax" {
                    BeforeAll {
                        $FileContents = Get-Content $_.Path -Raw
                    }

                    It "Should not be empty" {
                        $FileContents.Trim() | Should -Not -BeNullOrEmpty
                    }
                    
                    It "Should be syntactically valid" {
                        {[scriptblock]::Create($FileContents)} | Should -Not -Throw
                    }

                }

                Context "Structure" {
                    
                    BeforeAll {
                        $AST = [scriptblock]::Create((Get-Content $_.Path -Raw)).Ast
                        $ExpectedFunctionName = $_.Name
                    }

                    It "Should contain no named blocks" {
                        $AST.ParamBlock | Should -Be $null
                        $AST.DynamicParamBlock | Should -Be $null
                        $AST.BeginBlock | Should -Be $null
                        $AST.ProcessBlock | Should -Be $null
                        $AST.EndBlock.Unnamed | Should -Be $true
                    }

                    It "Should contain a single function definition, named `"<name>`"" {
                        $AST.EndBlock.Statements.Count | Should -Be 1
                        $AST.EndBlock.Statements[0] | Should -BeOfType [System.Management.Automation.Language.FunctionDefinitionAst]
                        $AST.EndBlock.Statements[0].Name | Should -Be $ExpectedFunctionName
                    }

                    It "Should have comment-based help [Public functions only]" -Skip:$(
                        -not ($_ -in $FunctionCache.Public)
                    ) {
                        $AST.EndBlock.Statements[0].GetHelpContent() | Should -Not -BeNullOrEmpty
                    }

                    ## TODO: assert documentation on all public function parameters

                }

            }

        }
    }
}