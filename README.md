# Minimalist Web Notepad for ASP.NET WebForms

This is an ASP.NET WebForms/C# port of [pereorga/minimalist-web-notepad](https://github.com/pereorga/minimalist-web-notepad), an open-source clone of the now-defunct notepad.cc: "a piece of paper in the cloud".

The original project demo is at https://notes.orga.cat or https://notes.orga.cat/whatever.

## Installation

Make sure the web server is allowed to write to the `_tmp` directory.

ASP.NET WebForms must be enabled. This port is intentionally conservative and should run on both .NET 2.0 and .NET 4.x application pools.

### On IIS

If the project resides in the document root and IIS URL Rewrite is available, the included `web.config` enables pretty URLs such as:

```
https://example.com/test
```

The rewrite rule maps them to:

```
index.aspx?note=test
```

If the project resides in a subdirectory such as `/notes`, the same rule maps:

```
https://example.com/notes/test
```

to:

```
https://example.com/notes/index.aspx?note=test
```

If URL Rewrite is not available, use the query-string form directly:

```
https://example.com/notes/index.aspx?note=test
```

### On Apache in front of IIS

Apache does not run ASP.NET WebForms itself. If Apache is used as the public web server in front of IIS, enable `mod_rewrite` and `mod_proxy` and put something like this in the site configuration.

If the project resides in the root directory:

```
RewriteEngine On
RewriteRule ^([a-zA-Z0-9_-]+)$ http://iis-backend/index.aspx?note=$1 [P,QSA,L]
```

If the project resides in a subdirectory:

```
RewriteEngine On
RewriteRule ^notes/([a-zA-Z0-9_-]+)$ http://iis-backend/notes/index.aspx?note=$1 [P,QSA,L]
```

### On Nginx in front of IIS

Nginx does not run ASP.NET WebForms itself. If Nginx is used as the public web server in front of IIS, put something like this in the configuration file.

If the project resides in the root directory:

```
location / {
    rewrite ^/([a-zA-Z0-9_-]+)$ /index.aspx?note=$1 break;
    proxy_pass http://iis-backend;
}
```

If the project resides in a subdirectory:

```
location ~* ^/notes/([a-zA-Z0-9_-]+)$ {
    rewrite ^/notes/([a-zA-Z0-9_-]+)$ /notes/index.aspx?note=$1 break;
    proxy_pass http://iis-backend;
}
```

If parameters need to be passed in Nginx (such as `?raw`), then `&$args` needs to be added to the end of the `$1` match:

```
location ~* ^/notes/([a-zA-Z0-9_-]+)$ {
    rewrite ^/notes/([a-zA-Z0-9_-]+)$ /notes/index.aspx?note=$1&$args break;
    proxy_pass http://iis-backend;
}
```

## Usage (CLI)

Using the command-line interface you can both save and retrieve notes. Here are some examples using `curl`.

Retrieve a note's content and save it to a local file:

```
curl https://example.com/notes/test > test.txt
```

Save specific text to a note:

```
curl https://example.com/notes/test -d 'hello,

welcome to my pad!
'
```

Save the content of a local file:

```
cat /etc/hosts | curl https://example.com/notes/hosts --data-binary @-
```

If URL Rewrite is not available, use the query-string form directly:

```
curl 'https://example.com/notes/index.aspx?note=test&raw=1' > test.txt
curl 'https://example.com/notes/index.aspx?note=test' -d 'hello'
```

## Copyright and license

Original project copyright 2012 Pere Orga <pere@orga.cat>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this work except in compliance with the License.
You may obtain a copy of the License at:

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
