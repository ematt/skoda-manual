#!/bin/bash
set -e

# if [ ! -e "style.css" ]; then
#     curl 'https://digital-manual.skoda-auto.com/resources/tenants/default/resources/style.css?t=20231123131356' > style.css
# fi
# if [ ! -e "print.css" ]; then
#     curl 'https://digital-manual.skoda-auto.com/resources/tenants/default/resources/print.css' > print.css
# fi

MANUAL=a2f0321d91cc34bfac1445252fd5b3f4_3_en_GB
REFERER="https://digital-manual.skoda-auto.com/w/en_GB/show/${MANUAL}?ct=${MANUAL}"
COOKIES='cb-enabled=enabled; dtCookie==3=sn=1C6023C0EECB0A9AC5E8BCBF92D339D3=perc=100000=ol=0=mul=1; JSESSIONID=E4C1AF5D111CE640297BA49F112DB197; BIGipServerP_SMBSTAP.app~P_SMBSTAP_pool=!Uo/Jgk56D8UqeZIB0gnUc0mGjTntSu6c/biTztu+eehZFiTO3xvoMPe9moCXYiTOvXADg2OocQtmtdY=; TS01e91aa3=01b06b1fecb9ecae834f24774d2e01e0623ab47a78fc45d7c2ae19742987f31237ce67358a54b2090b614cb660627eed92fb7076702aa95ce02a00f9a1be859f71f7e7ceeeaef70ce033cbb938487a4153359eb226'

mkdir -p images

MAXSECT=100

function grabImage() {
    IMG=$1
    >&2 echo "Image $IMG"

    curl -s "https://digital-manual.skoda-auto.com/public/media?${IMG}" -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0' -H 'Accept: image/avif,image/webp,*/*' -H 'Accept-Language: en-US,en;q=0.5' -H "Referer: $REFERER" -H "Cookie: $COOKIES" -H 'Sec-Fetch-Dest: image' -H 'Sec-Fetch-Mode: no-cors' -H 'Sec-Fetch-Site: same-origin' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' >images/$IMG
}

function handleSection() {
    local EXPR=$1
    local LABEL="$(cat /tmp/toc.json | jq -r "${EXPR}.label")"
    local CHILDREN="$(cat /tmp/toc.json | jq -r "${EXPR}.children | length")"
    local LINK=$(cat /tmp/toc.json | jq -r "${EXPR}.linkTarget")
    >&2 echo "$EXPR : $LABEL , with $CHILDREN children"
    local ID
    if [ -n "$LINK" ]; then
        ID="$LINK"
    else
        ID=$(echo "$LINK" | base64)
    fi

    echo "<div class='section' id='${ID}'>"
    echo "<div class='section-label'>${LABEL}</div>"

    if [ -n "$LINK" ]; then
        curl -s "https://digital-manual.skoda-auto.com/api/vw-topic/V1/topic?key=${LINK}&displaytype=desktop&language=en_GB" --compressed -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Connection: keep-alive' -H "Referer: $REFERER" -H "Cookie: $COOKIES" -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' | jq -r ".bodyHtml" > /tmp/entry.html

        # Grab content without <html>, replacing data-src for images with actual src
        cat /tmp/entry.html | sed 's|<?[-A-Za-z0-9 "=\.]*?>||g' | sed 's|<!DOCTYPE.*||g' | sed 's|^  PUBLIC ".*||g' | sed 's|<html[0-9"= a-z\-]*>||g' | sed 's|</html>||g' | sed 's/data-src="\/public\/media?/src="images\//g'

        # Grab images
        while read IMG; do
            if [ ! -e "images/$IMG" ]; then
                grabImage $IMG
            fi
        done < <(xmllint --xpath "//html//img/@data-src" /tmp/entry.html 2>/dev/null | sed 's/ data-src="\/public\/media?\(.*\)"/\1/g' | sed 's/&amp;/\&/g')
    fi

    local i
    local TOP
    TOP=$(( CHILDREN > MAXSECT ? MAXSECT : CHILDREN ))
    for ((i=0;i<TOP;i++)); do
        handleSection "$EXPR.children[${i}]"
    done

    echo "</div>"
}

function handleToc() {
    local EXPR=$1
    local PREFIX=$2
    local LABEL="$(cat /tmp/toc.json | jq -r "${EXPR}.label")"
    local CHILDREN="$(cat /tmp/toc.json | jq -r "${EXPR}.children | length")"
    local LINK=$(cat /tmp/toc.json | jq -r "${EXPR}.linkTarget")
    local ID
    if [ -n "$LINK" ]; then
        ID="$LINK"
    else
        ID=$(echo "$LINK" | base64)
    fi

    echo "<div class='toc-section'>"
    echo "<div><a class='toc-section-label' href='#${ID}'>${PREFIX:1}. ${LABEL}</a></div>"

    local i
    local TOP
    TOP=$(( CHILDREN > MAXSECT ? MAXSECT : CHILDREN ))
    for ((i=0;i<TOP;i++)); do
        handleToc "$EXPR.children[${i}]" "${PREFIX}.$((i+1))"
    done

    echo "</div>"
}

curl -s 'https://digital-manual.skoda-auto.com/api/web/V6/topic?key=599333bff3ba55cbac144525291a2266_1_en_GB&displaytype=topic&language=en_GB&query=undefined' --compressed -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Connection: keep-alive' -H "Referer: $REFERER" -H "Cookie: $COOKIES" -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' | jq .trees >/tmp/toc.json

echo "<html>"
echo "<head>"
echo "<title>Owner's Manual</title>"
echo '<link href="extra.css" rel="stylesheet" type="text/css"/>'
echo '</head>'
echo '<body>'
echo '<div class="toc">'
echo '<div class="toc-label">Table of contents</div>'
>&2 echo "Generating table of contents..."
handleToc ".[0]" ""
handleSection ".[0]"
echo '</div>'
echo "</body>"
echo "</html>"
