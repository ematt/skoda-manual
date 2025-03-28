# Skoda manual offline generator

Skoda is not (no longer) providing PDF or paper versions of manuals for their cars. This can be inconvenient if you're in a location without internet, or if you just like to browse or search through a manual.

This little script crawls the Skoda manual website and extracts one section at a time, building a large HTML file in the process. Additionally, any images are downloaded as well. This is combined with a bit of minimal CSS to make the result look half-way decent (feel free to customize this).

Please do not share any extracted manuals further than your own use, there's probably copyright on them.

## Prerequisites

You will need the following unix command-line tools:

- `bash`
- `curl`
- `sed`
- `xmllint`
- `jq`

And optionally [Calibre](https://calibre-ebook.com/), to conveniently convert the HTML to something else.

## Extraction process

Since the manual website requires certain cookies to deliver content, the process is a little convoluted:

- Go to [https://manual.skoda-auto.com/](https://manual.skoda-auto.com/) and select a manual. Click on *Show*, and the target manual, so you end up on a URL resembling `https://digital-manual.skoda-auto.com/w/en_GB/show/SOME-ID-HERE?ct=SOME-ID-HERE`
- Note the manual ID (marked `SOME-ID-HERE` above)
- We're now going to take the cookies from that site. Open up your Firefox Developer Console (or equivalent on other browsers) with *F12*.
- Go to the "Network" tab
- Reload the page
- Scroll up to the very first request, right-click it, and select "Copy Value" -> "Copy as cURL"
- Paste the result into any text editor. It should look like:
```bash
curl 'https://digital-manual.skoda-auto.com/w/en_GB/show/599333bff3ba55cbac144525291a2266_1_en_GB?ct=599333bff3ba55cbac144525291a2266_1_en_GB'
  --compressed -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:120.0) Gecko/20100101 Firefox/120.0'
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5'
  -H 'Accept-Encoding: gzip, deflate, br' -H 'Connection: keep-alive' -H 'Cookie: LOTS-OF-DATA-HERE' -H 'Upgrade-Insecure-Requests: 1'
  -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-site'
```
- Copy the content of the `Cookie:` header (marked `LOTS-OF-DATA-HERE` above) to the clipboard.
- Start a `bash` shell in this repository, and write (replacing where appropriate):
```bash
export COOKIES='PASTE-YOUR-COOKIES-HERE'
./skoda.sh PASTE-YOUR-MANUAL-ID-HERE LANGUAGE >manual.html
```
- This should create a `manual.html` file with your result, writing some progress info to `stderr`. Images are saved in the `images/` directory that's automatically created.
- If desired, you can convert the result to PDF or EPUB using Calibre's tools:
```
ebook-convert manual.html manual.epub
```
or
```
ebook-convert manual.html manual.pdf
```
