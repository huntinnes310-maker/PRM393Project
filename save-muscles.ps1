$resp = Invoke-RestMethod -Uri 'http://localhost:5028/api/muscles'
$muscles = $resp.value
$muscles | ConvertTo-Json -Depth 3 | Out-File -FilePath 'muscles.json' -Encoding UTF8
Write-Host "Muscles saved: $($muscles.Count)"
