param(
  [string]$Root = (Get-Location).Path
)

$textPattern = 'Text\(\s*(?:const\s*)?[\x27\x22]([^\x27\x22]{2,})[\x27\x22]'
$propertyPattern = '(?:labelText|hintText|helperText|tooltip|semanticsLabel)\s*:\s*[\x27\x22]([^\x27\x22]{2,})[\x27\x22]'
$excluded = @('TOTOTL', 'I N T G R X', 'DRONE PILOT & COMPANY PLATFORM')

$sources = [System.Collections.Generic.HashSet[string]]::new()
Get-ChildItem (Join-Path $Root 'lib') -Recurse -Filter *.dart |
  Where-Object { $_.FullName -notmatch 'generated_ui_translations.dart' } |
  ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    foreach ($pattern in @($textPattern, $propertyPattern)) {
      [regex]::Matches($content, $pattern) | ForEach-Object {
        $value = $_.Groups[1].Value
        if ($value -notmatch '\$' -and $excluded -notcontains $value) {
          [void]$sources.Add($value)
        }
      }
    }
  }

function Decode-DartString([string]$value) {
  return $value.Replace('\\n', "`n").Replace('\\\'', "'").Replace('\\\$', '$').Replace('\\\\', '\\')
}

function Escape-DartString([string]$value) {
  return $value.Replace('\\', '\\\\').Replace("'", "\\'").Replace('$', '\\$').Replace("`r`n", '\\n').Replace("`n", '\\n')
}

function Translate([string]$source, [string]$target) {
  $query = [uri]::EscapeDataString($source)
  $uri = "https://api.mymemory.translated.net/get?q=$query&langpair=en%7C$target"
  try {
    $result = Invoke-RestMethod -Uri $uri -TimeoutSec 20
    $translation = [string]$result.responseData.translatedText
    if ([string]::IsNullOrWhiteSpace($translation)) { return $source }
    return [System.Net.WebUtility]::HtmlDecode($translation)
  } catch {
    return $source
  }
}

$ar = [ordered]@{}
$de = [ordered]@{}
$items = @($sources | Sort-Object)
for ($index = 0; $index -lt $items.Count; $index++) {
  $source = Decode-DartString $items[$index]
  $ar[$source] = Translate $source 'ar'
  $de[$source] = Translate $source 'de'
  if (($index + 1) % 20 -eq 0) { Write-Output "Translated $($index + 1) of $($items.Count) labels" }
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('/// Generated interface-copy translations. Do not edit manually.')
$lines.Add('const Map<String, Map<String, String>> generatedUiTranslations = {')
foreach ($pair in @(@('ar', $ar), @('de', $de))) {
  $lines.Add("  '$($pair[0])': {")
  foreach ($entry in $pair[1].GetEnumerator()) {
    $lines.Add("    '$(Escape-DartString $entry.Key)': '$(Escape-DartString ([string]$entry.Value))',")
  }
  $lines.Add('  },')
}
$lines.Add('};')

$destination = Join-Path $Root 'lib\core\localization\generated_ui_translations.dart'
[System.IO.File]::WriteAllLines($destination, $lines, [System.Text.UTF8Encoding]::new($false))
