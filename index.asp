<%@ Language="VBScript" CodePage="65001" %>
<%
Option Explicit

Const SAVE_DIR = "_tmp"
Const NOTE_CHARS = "234579abcdefghjkmnpqrstwxyz"

Response.CodePage = 65001
Response.CharSet = "utf-8"
Response.Buffer = True
Response.Expires = -1
Response.AddHeader "Cache-Control", "no-store"

Dim note
note = GetNoteName()

If Not IsValidNoteName(note) Then
    Response.Status = "302 Found"
    Response.AddHeader "Location", GenerateNoteName()
    Response.End
End If

EnsureSaveDir()

Dim notePath
notePath = Server.MapPath(SAVE_DIR & "/" & note)

If UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST" Then
    Dim postedText
    postedText = GetPostedText()
    If Len(postedText) = 0 Then
        DeleteFileIfExists notePath
    Else
        WriteUtf8File notePath, postedText
    End If
    Response.End
End If

If WantsRaw() Then
    If FileExists(notePath) Then
        Response.ContentType = "text/plain"
        Response.Write ReadUtf8File(notePath)
    Else
        Response.Status = "404 Not Found"
    End If
    Response.End
End If

Dim initialText
initialText = ""
If FileExists(notePath) Then
    initialText = ReadUtf8File(notePath)
End If

Function GetNoteName()
    GetNoteName = Request.QueryString("note")
End Function

Function IsValidNoteName(value)
    Dim i, ch
    IsValidNoteName = False
    If Len(value) = 0 Or Len(value) > 64 Then Exit Function
    For i = 1 To Len(value)
        ch = Mid(value, i, 1)
        If InStr(1, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-", ch, vbBinaryCompare) = 0 Then
            Exit Function
        End If
    Next
    IsValidNoteName = True
End Function

Function GenerateNoteName()
    Dim i, index, result
    Randomize
    result = ""
    For i = 1 To 5
        index = Int(Rnd() * Len(NOTE_CHARS)) + 1
        result = result & Mid(NOTE_CHARS, index, 1)
    Next
    GenerateNoteName = result
End Function

Sub EnsureSaveDir()
    Dim fso, path
    path = Server.MapPath(SAVE_DIR)
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(path) Then
        fso.CreateFolder(path)
    End If
    Set fso = Nothing
End Sub

Function FileExists(path)
    Dim fso
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    FileExists = fso.FileExists(path)
    Set fso = Nothing
End Function

Sub DeleteFileIfExists(path)
    Dim fso
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(path) Then
        fso.DeleteFile path, True
    End If
    Set fso = Nothing
End Sub

Function GetPostedText()
    Dim rawBody, contentType, parts, i, eqPos, key, value
    rawBody = ReadRequestBodyUtf8()
    contentType = LCase(Request.ServerVariables("CONTENT_TYPE"))

    If InStr(contentType, "application/x-www-form-urlencoded") > 0 Then
        parts = Split(rawBody, "&")
        For i = 0 To UBound(parts)
            eqPos = InStr(parts(i), "=")
            If eqPos > 0 Then
                key = Server.URLDecode(Left(parts(i), eqPos - 1))
                If key = "text" Then
                    value = Mid(parts(i), eqPos + 1)
                    GetPostedText = Server.URLDecode(value)
                    Exit Function
                End If
            End If
        Next
    End If

    GetPostedText = rawBody
End Function

Function ReadRequestBodyUtf8()
    Dim total, bytes, stream
    total = Request.TotalBytes
    If total = 0 Then
        ReadRequestBodyUtf8 = ""
        Exit Function
    End If

    bytes = Request.BinaryRead(total)
    Set stream = Server.CreateObject("ADODB.Stream")
    stream.Type = 1
    stream.Open
    stream.Write bytes
    stream.Position = 0
    stream.Type = 2
    stream.Charset = "utf-8"
    ReadRequestBodyUtf8 = stream.ReadText
    stream.Close
    Set stream = Nothing
End Function

Sub WriteUtf8File(path, text)
    Dim textStream, binaryStream
    Set textStream = Server.CreateObject("ADODB.Stream")
    textStream.Type = 2
    textStream.Charset = "utf-8"
    textStream.Open
    textStream.WriteText text
    textStream.Position = 3

    Set binaryStream = Server.CreateObject("ADODB.Stream")
    binaryStream.Type = 1
    binaryStream.Open
    textStream.CopyTo binaryStream
    binaryStream.SaveToFile path, 2

    binaryStream.Close
    textStream.Close
    Set binaryStream = Nothing
    Set textStream = Nothing
End Sub

Function ReadUtf8File(path)
    Dim stream
    Set stream = Server.CreateObject("ADODB.Stream")
    stream.Type = 2
    stream.Charset = "utf-8"
    stream.Open
    stream.LoadFromFile path
    ReadUtf8File = stream.ReadText
    stream.Close
    Set stream = Nothing
End Function

Function HasQueryKey(name)
    Dim key
    HasQueryKey = False
    For Each key In Request.QueryString
        If LCase(CStr(key)) = LCase(name) Then
            HasQueryKey = True
            Exit Function
        End If
    Next
End Function

Function WantsRaw()
    Dim ua
    ua = Request.ServerVariables("HTTP_USER_AGENT")
    WantsRaw = HasQueryKey("raw") Or Left(ua, 4) = "curl" Or Left(ua, 4) = "Wget"
End Function
%><!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%=Server.HTMLEncode(note)%></title>
<link rel="icon" href="favicon.ico" sizes="any">
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<style>
body {
    margin: 0;
    background: #ebeef1;
}
.container {
    position: absolute;
    top: 20px;
    right: 20px;
    bottom: 20px;
    left: 20px;
}
#content {
    margin: 0;
    padding: 20px;
    overflow-y: auto;
    resize: none;
    width: 100%;
    height: 100%;
    box-sizing: border-box;
    border: 1px solid #ddd;
    outline: none;
}
#printable {
    display: none;
}
@media (prefers-color-scheme: dark) {
    body {
        background: #333b4d;
    }
    #content {
        background: #24262b;
        color: #fff;
        border-color: #495265;
    }
}
@media print {
    .container {
        display: none;
    }
    #printable {
        display: block;
        white-space: pre-wrap;
        word-break: break-word;
    }
}
</style>
</head>
<body>
<div class="container">
<textarea id="content"><%=Server.HTMLEncode(initialText)%></textarea>
</div>
<pre id="printable"></pre>
<script>
function uploadContent() {
    if (content !== textarea.value) {
        var temp = textarea.value;
        var request = new XMLHttpRequest();
        request.open('POST', window.location.href, true);
        request.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
        request.onload = function() {
            if (request.readyState === 4) {
                content = temp;
                setTimeout(uploadContent, 1000);
            }
        };
        request.onerror = function() {
            setTimeout(uploadContent, 1000);
        };
        request.send('text=' + encodeURIComponent(temp));

        printable.removeChild(printable.firstChild);
        printable.appendChild(document.createTextNode(temp));
    }
    else {
        setTimeout(uploadContent, 1000);
    }
}

var textarea = document.getElementById('content');
var printable = document.getElementById('printable');
var content = textarea.value;

printable.appendChild(document.createTextNode(content));

textarea.focus();
uploadContent();
</script>
</body>
</html>
