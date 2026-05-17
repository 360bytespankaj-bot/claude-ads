#Requires -Version 5.1
<#
.SYNOPSIS
    Claude Ads Uninstaller for Windows (multi-host).
.DESCRIPTION
    Removes every ads-* sub-skill directory plus the orchestrator and bundled
    agents from the chosen host's install root. Uses glob discovery so new
    sub-skills don't require uninstaller updates.
.PARAMETER Target
    Which host CLI to uninstall from. Default: claude.
#>

param(
    [ValidateSet('claude','codex','cursor','windsurf','gemini','goose')]
    [string]$Target = 'claude'
)

$ErrorActionPreference = "Stop"

function Resolve-TargetPaths {
    param([string]$T)
    switch ($T) {
        'claude'   { return @{ SkillBase = Join-Path $env:USERPROFILE ".claude\skills";                                AgentDir = Join-Path $env:USERPROFILE ".claude\agents" } }
        'codex'    { return @{ SkillBase = Join-Path $env:USERPROFILE ".codex\skills";                                 AgentDir = Join-Path $env:USERPROFILE ".codex\agents" } }
        'cursor'   { return @{ SkillBase = Join-Path $env:USERPROFILE ".cursor\extensions\claude-ads\skills";          AgentDir = Join-Path $env:USERPROFILE ".cursor\extensions\claude-ads\agents" } }
        'windsurf' { return @{ SkillBase = Join-Path $env:USERPROFILE ".windsurf\skills";                              AgentDir = Join-Path $env:USERPROFILE ".windsurf\agents" } }
        'gemini'   { return @{ SkillBase = Join-Path $env:USERPROFILE ".gemini\extensions\claude-ads\skills";          AgentDir = Join-Path $env:USERPROFILE ".gemini\extensions\claude-ads\agents" } }
        'goose'    { return @{ SkillBase = Join-Path $env:USERPROFILE ".config\goose\skills";                          AgentDir = Join-Path $env:USERPROFILE ".config\goose\agents" } }
        default    { throw "Unknown target: $T" }
    }
}

function Main {
    $paths = Resolve-TargetPaths -T $Target
    $SkillBase = $paths.SkillBase
    $AgentDir = $paths.AgentDir

    Write-Host "Uninstalling Claude Ads from $SkillBase and $AgentDir..."

    # Remove orchestrator
    $MainSkill = Join-Path $SkillBase "ads"
    if (Test-Path $MainSkill) {
        Remove-Item -Path $MainSkill -Recurse -Force
    }

    # Remove all ads-* sub-skills via glob
    if (Test-Path $SkillBase) {
        Get-ChildItem -Path $SkillBase -Directory -Filter "ads-*" -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-Item -Path $_.FullName -Recurse -Force
        }
    }

    # Remove bundled audit + creative agents
    $Agents = @(
        "audit-google", "audit-meta", "audit-creative",
        "audit-tracking", "audit-budget", "audit-compliance",
        "audit-amazon", "audit-attribution", "audit-server-side",
        "creative-strategist", "visual-designer", "copy-writer", "format-adapter"
    )
    foreach ($agent in $Agents) {
        $AgentPath = Join-Path $AgentDir "$agent.md"
        if (Test-Path $AgentPath) {
            Remove-Item -Path $AgentPath -Force
        }
    }

    Write-Host "[OK] Claude Ads uninstalled." -ForegroundColor Green
}

Main
