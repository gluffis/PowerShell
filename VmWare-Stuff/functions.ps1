#
# collection of functions
#
# GluffiS <gluffis @ gmail.com >
#

function PostToMattermost($text) {
    $uri = "https://<uri to mattermost hook>"
    $user = "<user>"
    $payload = @{ text=$text ; username=$user;icon_url="No icon"}
    try {
        Invoke-RestMethod -uri $uri -Method post -ContentType 'application/json' -body (ConvertTo-Json $payload) } catch {}
    }

function PushToInflux($influxstring) {
    $uri = 'http://<url to influxdb database'
    try { Invoke-RestMethod -uri $uri -Method POST -body $influxstring  } catch {}
}