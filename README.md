# ConvertFrom-RegEx
PowerShell module for deserializing text via Regular Expressions (RegEx)

## Overview
PowerShell's data transformation and manipulation functions work best on objects - however, many scenarios still require interacting with serialized, stringified data. Common structured formats (JSON, XML, YAML, etc.) have highly-performant parsers available, but not every application uses these. In-box commandlets like `Select-String` provide an interface into the .NET RegEx classes, but the output from these cmdlets is convoluted and requires non-trivial work to condense into plain objects.

`ConvertFrom-RegEx` is intended as a "parser provider" to enable fast object deserialization through .NET Regular Expressions. One or more RegEx patterns can be provided against an input text corpus, and matches will be automatically rehydrated into PowerShell objects. 

The module uses `Select-String` internally to perform matching, with some additional abstractions to convert matches into usable objects. (Many parameters function similarly to those exposed by `Select-String`.)

## Features
* Object deserialization from string data
* Object deserialization from file(s) (akin to `Select-String -Path` or `Select-String -LiteralPath`)

## Supported Versions
* Windows PowerShell 5.1
* PowerShell 7.2 or later

## Dependencies
None. `ConvertFrom-RegEx` is self-contained and relies only upon in-box PowerShell/.NET functionality.

## Installation
`ConvertFrom-RegEx` is available [on the PowerShell Gallery](https://www.powershellgallery.com/packages/ConvertFrom-RegEx). To install it, use `Install-Module` from the PowerShellGet module:

```powershell
Install-Module ConvertFrom-RegEx
```

> [!NOTE]
> PowerShellGet ships in-box with PowerShell 5.1 and later - however, the version installed may lack the requisite features needed to install modules from the PowerShell Gallery.
>   
> Updating PowerShellGet to the latest version is recommended - see [Installing PowerShellGet](https://learn.microsoft.com/en-us/powershell/scripting/gallery/installing-psget) on Microsoft Docs for more information.

## Usage/Examples

To use ConvertFrom-RegEx, import the module into your PowerShell session and pass string data or files to the `ConvertFrom-RegEx` commandlet. Pipeline and parameter-based input is supported - see examples below.

### Simple deserialization from pipeline

```powershell
PS> "A=1, B=2, C=3, C=4" | ConvertFrom-RegEx -Pattern "A=(?<A>\d+), B=(?<B>\d+), (?:C=(?<C>\d+)[,\s]*)+"

A B C
- - -
1 2 {3, 4}
```
Match the string `A=1, B=2, C=3, C=4` with the provided regular expression. Values from capture groups A and B are directly translated to their corresponding properties. As capture group C captures multiple times within a given match, its captures are returned as an array.

### Deserialize multiple objects from one line

```powershell
"A=1, B=2, C=3, C=4 | A=3, B=4, C=5, C=6" | ConvertFrom-RegEx -Pattern "A=(?<A>\d+), B=(?<B>\d+), (?:C=(?<C>\d+)[,\s]*)+" -AllMatches

A B C
- - -
1 2 {3, 4}
3 4 {5, 6}
```
Match the string `A=1, B=2, C=3, C=4 | A=3, B=4, C=5, C=6` with the same regular expression as the previous example. As the `-AllMatches` parameter was specified, both the first and second halves of the string each result in their own object.




## Limitations
* `Select-String` does not expose a method for setting the .NET RegEx `MatchTimeout` parameter. Patterns that require excessive backtracking (nested optional qualifiers, lookarounds, etc.) may exhibit performance degradation. Untrusted source content can contain strings designed to exploit this behavior, leading to a denial-of-service attack.

  For more information, see [Backtracking in Regular Expressions](https://learn.microsoft.com/en-us/dotnet/standard/base-types/backtracking-in-regular-expressions) on Microsoft Docs.