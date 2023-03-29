# Set up API access token
$AccessToken = "YOUR GENIUS TOKEN HERE"

# Define function to check for profanity in a string
function Check-Profanity ($Text) {
    $url = "https://www.purgomalum.com/service/containsprofanity?text=$Text"
    $result = Invoke-WebRequest $url
    return ($result.Content -eq "true")
}

# Get list of files in the directory
$Directory = "C:\YOUR\SONG\DIRECTORY\HERE"
$Files = Get-ChildItem -Path $Directory -Filter "*.mp3"

# Loop through files and check for profanity in song and artist names
foreach ($File in $Files) {
    $Name = $File.Name.Replace(".mp3", "")
    Write-Output "Searching for $Name ..."

    $url = "https://api.genius.com/search?q=$Name"
    $Headers = @{ "Authorization" = "Bearer $AccessToken" }
    $result = Invoke-WebRequest -Uri $url -Headers $Headers | ConvertFrom-Json
    $LyricsUrl = $result.response.hits[0].result.url

    $html = Invoke-WebRequest -Uri $LyricsUrl
    $regex = '(?<=<div[^>]*data-lyrics-container[^>]*>)([\s\S]*?)(?=<\/div\b(?![^>]*\bLyrics__Footer\b))'
    $Lyrics = [regex]::Matches($html.Content, $regex) | ForEach-Object { $_.Groups[1].Value.Trim() }

    $Lyrics = [System.Web.HttpUtility]::HtmlDecode([regex]::Replace($Lyrics, '<.*?>', ' '))

    $UniqueWords = $Lyrics -split '\W+' | Select-Object -Unique

    $IsProfane = $false
    # Loop through each unique word and check for profanity
    foreach ($Word in $UniqueWords) {
        $IsProfane = $IsProfane -or (Check-Profanity $Word)
        if ($IsProfane) {
            $BadWord = $Word
            break
        }
    }

    # Output result
    if ($IsProfane) {
        Write-Output "$Name contains profanity $BadWord" | Out-File -FilePath "C:\OUTPUT\profanity.txt" -Append
    }
    else {
        Write-Output "$Name is clean"
    }
}
