param (
	[string]$source,
	[string]$targetList,
	[string]$sourceDirectory,
	[string]$targetDirectory = $sourceDirectory
)

function Get-CharacterIdByName {
	param (
		[string]$name
	)

	$esiBaseUrl = "https://esi.evetech.net/latest"
	$searchEndpoint = "/universe/ids/"
	$searchUrl = "$esiBaseUrl$searchEndpoint"

	try {
		$response = Invoke-RestMethod -Uri $searchUrl -Method Post -Body (ConvertTo-Json @($name))
		if ($response.characters -and $response.characters.Count -gt 0) {
			return $response.characters[0].id
		}
		else {
			Write-Error "Character not found"
			return $null
		}
	}
 catch {
		Write-Error "Failed to call ESI API: $_"
		return $null
	}
}

$targets = $targetList -split "[,;\s]+" | Where-Object { $_ -ne "" }
Write-Host "Source Character: $source"
Write-Host "Target Characters: $($targets -join ', ')"
# $localAppData = [System.Environment]::GetFolderPath('LocalApplicationData')
# $eveConfigRootPath = Join-Path -Path $localAppData -ChildPath "CCP/EVE"
$sourceCharacterConfigFileMap = @{}
$targetCharacterConfigFileMap = @{}
Get-ChildItem -Path $sourceDirectory -Filter "core_char_*.dat" -Recurse | ForEach-Object {
	if ($_ -match 'core_char_(\d+).dat') {
		$charId = [long]$matches[1]
		$sourceCharacterConfigFileMap[$charId] = $_.FullName
	}
}
Get-ChildItem -Path $targetDirectory -Filter "core_char_*.dat" -Recurse | ForEach-Object {
	if ($_ -match 'core_char_(\d+).dat') {
		$charId = [long]$matches[1]
		$targetCharacterConfigFileMap[$charId] = $_.FullName
	}
}
$sourceCharacterId = Get-CharacterIdByName -name $source
foreach ($targetCharacterName in $targets) {
	$targetCharacterId = Get-CharacterIdByName -name $targetCharacterName
	if ($targetCharacterId -and $sourceCharacterConfigFileMap.ContainsKey($sourceCharacterId) -and $targetCharacterConfigFileMap.ContainsKey($targetCharacterId)) {
		$sourceFile = $sourceCharacterConfigFileMap[$sourceCharacterId]
		$targetFile = $targetCharacterConfigFileMap[$targetCharacterId]
		Copy-Item -Path $sourceFile -Destination $targetFile -Force
		Write-Host "Copied settings from $source to $targetCharacterName"
	}
	else {
		Write-Error "Could not find configuration files for $source or $targetCharacterName"
		if (-not $sourceCharacterConfigFileMap.ContainsKey($sourceCharacterId)) {
			Write-Error "Source character configuration file not found with ${sourceCharacterId}."
		}
		if (-not $targetCharacterConfigFileMap.ContainsKey($targetCharacterId)) {
			Write-Error "Target character configuration file not found with ${targetCharacterId}."
		}
	}
}