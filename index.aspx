<%@ Page Language="C#" ValidateRequest="false" %>
<%@ Import Namespace="System" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Web" %>
<script runat="server">
private const string SaveDir = "_tmp";
private const string NoteChars = "234579abcdefghjkmnpqrstwxyz";

protected string Note = "";
protected string InitialText = "";

protected void Page_Load(object sender, EventArgs e)
{
    Response.Cache.SetNoStore();

    Note = GetNoteName();
    if (!IsValidNoteName(Note))
    {
        Response.StatusCode = 302;
        Response.RedirectLocation = GenerateNoteName();
        Response.End();
        return;
    }

    EnsureSaveDir();
    string path = Server.MapPath(SaveDir + "/" + Note);

    if (String.Equals(Request.HttpMethod, "POST", StringComparison.OrdinalIgnoreCase))
    {
        string text = GetPostedText();
        if (text.Length == 0)
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }
        else
        {
            File.WriteAllText(path, text, new UTF8Encoding(false));
        }
        Response.End();
        return;
    }

    if (WantsRaw())
    {
        if (File.Exists(path))
        {
            Response.ContentType = "text/plain; charset=utf-8";
            Response.Write(File.ReadAllText(path, Encoding.UTF8));
        }
        else
        {
            Response.StatusCode = 404;
        }
        Response.End();
        return;
    }

    Response.ContentType = "text/html; charset=utf-8";
    InitialText = File.Exists(path) ? File.ReadAllText(path, Encoding.UTF8) : "";
}

private string GetNoteName()
{
    return Request.QueryString["note"];
}

private bool IsValidNoteName(string note)
{
    return !String.IsNullOrEmpty(note) && note.Length <= 64 && Regex.IsMatch(note, "^[A-Za-z0-9_-]+$");
}

private string GenerateNoteName()
{
    Random random = new Random();
    StringBuilder builder = new StringBuilder(5);
    for (int i = 0; i < 5; i++)
    {
        builder.Append(NoteChars[random.Next(NoteChars.Length)]);
    }
    return builder.ToString();
}

private void EnsureSaveDir()
{
    string path = Server.MapPath(SaveDir);
    if (!Directory.Exists(path))
    {
        Directory.CreateDirectory(path);
    }
}

private string GetPostedText()
{
    string formText = Request.Form["text"];
    if (formText != null)
    {
        return formText;
    }

    Stream input = Request.InputStream;
    if (input.CanSeek)
    {
        input.Position = 0;
    }

    StreamReader reader = new StreamReader(input, Encoding.UTF8);
    return reader.ReadToEnd();
}

private bool WantsRaw()
{
    bool hasRaw = false;
    string[] keys = Request.QueryString.AllKeys;
    for (int i = 0; i < keys.Length; i++)
    {
        if (String.Equals(keys[i], "raw", StringComparison.OrdinalIgnoreCase))
        {
            hasRaw = true;
            break;
        }
    }

    string ua = Request.UserAgent == null ? "" : Request.UserAgent;
    return hasRaw || ua.StartsWith("curl") || ua.StartsWith("Wget");
}
</script>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%=HttpUtility.HtmlEncode(Note)%></title>
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
<textarea id="content"><%=HttpUtility.HtmlEncode(InitialText)%></textarea>
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
