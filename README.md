# Dockerfile - ASP.NET Windows container with support for web.config overrides at startup

This image can be used just like `microsoft/aspnet`. At container startup, it'll perform these additional steps, in order:

1. If `C:\web-config-transform\transform.config` exists, it'll use this file to transform the Web.config
1. Override Web.config with environment variables:
    - Environment variables prefixed with `APPSETTING_` will override the corresponding app setting value (without the prefix)
    - Environment variables prefixed with `CONNSTR_` will override the corresponding connection string (without the prefix)

More information: https://anthonychu.ca/post/overriding-web-config-settings-environment-variables-containerized-aspnet-apps/

## Usage

To containerize an existing ASP.NET 4.x application:

```dockerfile
FROM anthonychu/aspnet:4.7.1-windowsservercore-1709
WORKDIR /inetpub/wwwroot
COPY sample-aspnet-4x .
```

Assuming `C:\transform` contains a file named `transform.config`, apply the web.config transformation at container startup:

```
PS> docker run -d -p 80:80 -v C:\transform:C:\web-config-transform sample-winforms-app
```

Override an app setting named `PageTitle` and a connection string named `DefaultConnection` using environment variables:

```
PS> docker run -d -p 80:80 -e APPSETTING_PageTitle=Foo -e CONNSTR_DefaultConnection="connection string from environment" sample-winforms-app
```

Apply web.config transform, then override the `PageTitle` app setting with an environment variable:

```
PS> docker run -d -p 80:80 -e APPSETTING_PageTitle=Foo -v C:\transform:C:\web-config-transform sample-winforms-app
```
