
function WebSite {
    <#
    .SYNOPSIS
        Test a Web Site
    .DESCRIPTION
        Used To Determine if Web Site is Running and Validate Various Properties
    .EXAMPLE
        WebSite TestSite { Should -Be Started }
    .EXAMPLE
        WebSite TestSite 'Applications["/"].Path' { Should -Be '/' }
    .EXAMPLE
      WebSite TestSite ProcessModel.IdentityType { Should -Be 'ApplicationPoolIdentity'}
    .NOTES
        Assertions: Be
    #>
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("Measure-RequiresModules\Measure-RequiresModules", "")]
    param(
        #The name of the Web Site to be Tested
        [Parameter(Mandatory, Position = 1, ParameterSetName = "Default")]
        [Parameter(Mandatory, Position = 1, ParameterSetName = "Property")]
        [Alias("Path")]
        [string]$Target,

        # The Property to be expanded. If Ommitted, Property Will Default to Status. Can handle nested objects
        # within properties
        [Parameter(Position = 2, ParameterSetName = "Property")]
        [Parameter(Position = 2, ParameterSetName = "Index")]
        [string]$Property,

        [Parameter(Position = 3, ParameterSetName = "Index")]

        # A Script Block defining a Pester Assertion.
        [Parameter(Mandatory, Position = 2, ParameterSetName = "Default")]
        [Parameter(Mandatory, Position = 3, ParameterSetName = "Property")]
        [scriptblock]$Should
    )

    begin {
        $IISAdmin = Get-Module -Name 'IISAdministration'
        if ($IISAdmin) {
            Import-Module IISAdministration
        } else {
            function Get-IISSite {
                <#
                .SYNOPSIS
                    Get the IIS Site from the localhost using the ServerManager
                .DESCRIPTION
                    If the IISAdministration module is not installed, this function can be used to retrieve the IIS site
                    using ServerManager.  This function will clash with the IISAdministration module function if it exists,
                    so only load it if it isn't.
                .EXAMPLE
                    Get-IISSite -Name "default"
                #>
                [CmdletBinding()]
                param(
                    [Parameter(Mandatory = $true,
                        Position = 1)]
                    [string]$Name
                )

                begin {
                    [System.Reflection.Assembly]::LoadFrom("$($Env:windir)\system32\inetsrv\Microsoft.Web.Administration.dll") | Out-Null
                    $ServerManager = [Microsoft.Web.Administration.ServerManager]::OpenRemote("localhost")
                }

                process {
                    try {
                        Write-Verbose "Getting site $Name"
                        Write-Output $ServerManager.Sites[$Name]
                    }

                    catch {
                        Write-Warning $Error[0]
                    }
                }

                end {
                    $ServerManager.Dispose()
                }
            }
        }
        $expression = $null
        $params = $null
    }
    process {
        if (-not $PSBoundParameters.ContainsKey('Property')) {
            $Property = 'State'
            $PSBoundParameters.add('Property', $Property)
            $expression = { Get-IISSite -Name '$Target' -ErrorAction SilentlyContinue }
            $params = Get-PoshspecParam -TestName WebSite -TestExpression $expression @PSBoundParameters
        }

        if ($Property -like '*.*' -or $Property -like '*(*' -or $Property -like '*)*') {
            $expression = { Get-IISSite -Name '$Target' -ErrorAction SilentlyContinue }
            $params = Get-PoshspecParam -TestName Website -TestExpression $expression -Target $Target -Should $Should -PropertyExpression $Property
        } else {
            $expression = { Get-IISSite -Name '$Target' -ErrorAction SilentlyContinue }
            $params = Get-PoshspecParam -TestName WebSite -TestExpression $expression @PSBoundParameters
        }
    }
    end {
        Invoke-PoshspecExpression @params
    }
}
