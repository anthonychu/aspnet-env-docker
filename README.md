# Dockerfile - ASP.NET Windows container with support for web.config overrides at startup

This image can be used just like [`microsoft/aspnet`](https://hub.docker.com/r/microsoft/aspnet/). At container startup, it'll perform these additional steps, in order:

1. If `C:\web-config-transform\transform.config` exists, it'll use this file to transform the Web.config
1. Override Web.config with environment variables:
    - Environment variables prefixed with `APPSETTING_` will override the corresponding app setting value (without the prefix)
    - Environment variables prefixed with `CONNSTR_` will override the corresponding connection string (without the prefix)
1. Override Web.config values with kubernetes secrets
    - Secrets prefixed with `APPSETTING_` will override the corresponding app setting value (without the prefix)
    - Secrets prefixed with `CONNSTR_` will override the corresponding connection string (without the prefix)

More information: <https://anthonychu.ca/post/overriding-web-config-settings-environment-variables-containerized-aspnet-apps/>

## Creating a base aspnet-env-docker image

There are some pre-created base images in [docker hub](https://hub.docker.com/r/anthonychu/aspnet/).

If the image you want isn't there then it is simple to create your own base image to use.

Once you have identified the version of the [microsoft/aspnet](https://hub.docker.com/r/microsoft/aspnet/) image that you want to base the image on, update the Dockerfile e.g.

```Dockerfile
FROM microsoft/aspnet:4.7.2-windowsservercore-1803
...
```

Then run docker from the aspnet-env-docker folder to build the image

```posh
PS> docker build -t yourrepo/aspnet .
```

## Building an image with your application

To containerize an existing ASP.NET 4.x application build on either one of the precreated images or the image you just built:

```dockerfile
FROM anthonychu/aspnet:4.7.1-windowsservercore-1709
WORKDIR /inetpub/wwwroot
COPY sample-aspnet-4x .
```

## Applying web.config transforms

Assuming `C:\transform` contains a file named `transform.config`, apply the web.config transformation at container startup:

```posh
PS> docker run -d -p 80:80 -v C:\transform:C:\web-config-transform sample-webforms-app
```

## Specifying app settings and connection strings with docker

Docker allows you to specify environment variables for a container when you run it.

This project allows you to override app settings by using environment variables prefixed with `APPSETTING_` and connection strings with environment variables prefixed with `CONNSTR_`.

To override an app setting named `PageTitle` and a connection string named `DefaultConnection` using environment variables:

```posh
PS> docker run -d -p 80:80 -e APPSETTING_PageTitle=Foo -e CONNSTR_DefaultConnection="connection string from environment" sample-webforms-app
```

This can be combined, so to apply a web.config transform and then override the `PageTitle` app setting with an environment variable:

```posh
PS> docker run -d -p 80:80 -e APPSETTING_PageTitle=Foo -v C:\transform:C:\web-config-transform sample-webforms-app
```

## Specifying app settings and connection strings with Kubernetes

### Environment variables

With Kubernetes we can use both environment variables and secrets to override web.config values.

To use environment variables we can create a deployment with the following YAML

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
    labels:
        run: sample-webforms-app
    name: sample-webforms-app
spec:
    replicas: 1
    selector:
    matchLabels:
        run: sample-webforms-app
    template:
        metadata:
            labels:
                run: sample-webforms-app
        spec:
            containers:
                - image: sample-webforms-app
                  imagePullPolicy: Always
                  name: sample-webforms-app
                  ports:
                  - containerPort: 80
                    protocol: TCP
                env:
                - name: APPSETTING_PageTitle
                  value: "Foo"
                - name: CONNSTR_DefaultConnection
                  value: "connection string from environment"
            restartPolicy: Always
```

### Secrets

You can use Kubernetes secrets instead of, or in combination with, environment variables.

When you create a Kubernetes secret the value has to be base64 encoded. The following PowerShell function provides a quick way to do this .

```posh
function Base64Encode($value){
    [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($value))
}
```

E.g.

```posh
PS> Base64Encode "Hello World"
SGVsbG8gV29ybGQ=
```

We can create secrets for app settings and connection strings in a similar way as above

```yaml
apiVersion: v1
kind: Secret
metadata:
    name: myaspnetapp-secret
type: Opaque
data:
    APPSETTING_PageTitle: VGhpcyBpcyB0aGUgdGl0bGUh
    CONNSTR_DefaultConnection: Q29ubmVjdGlvbiBzdHJpbmcgaGVyZQ==
```

To use the secrets with a deployment, mount them into the pod:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
    labels:
        run: myaspnetapp
    name: myaspnetapp
spec:
    replicas: 1
    selector:
    matchLabels:
        run: myaspnetapp
    template:
        metadata:
            labels:
                run: myaspnetapp
        spec:
            containers:
                - image: stuartleeks/myaspnetapp
                  imagePullPolicy: Always
                  name: myaspnetapp
                  ports:
                  - containerPort: 80
                    protocol: TCP
                env:
                - name: ASPNET_SECRETS_PATH
                   value: "c:\\secrets"
                - name: APPSETTING_PageText
                   value: "Hello from an environment variable set in the Kubernetes deployment spec"
                volumeMounts:
                    - name: test-secret
                      mountPath: "c:\\secrets"
            volumes:
                - name: test-secretsecret:
                      secretName: myaspnetapp-test-secret
                      defaultMode: 256
            restartPolicy: Always
```

In the example above we are mounting the previously defined secret in `c:\secrets` and also specifying an app setting override via an environment variable. If the same override exists in both environment variables and secrets, the secret version is used.

There is also an additional `ASPNET_SECRETS_PATH` in the example above. This is optional if you mount the secrets in `c:\secrets` but allows you tell the scripts where to load the secrets from if you want to mount them to a different location.


## More information

Check out these blog posts for more:
- [Overriding Web.config Settings with Environment Variables in Containerized ASP.NET Applications (with No Code Changes)](https://anthonychu.ca/post/overriding-web-config-settings-environment-variables-containerized-aspnet-apps/)
- [ASP.NET Web.config Transforms in Windows Containers - Revisited](https://anthonychu.ca/post/aspnet-web-config-transforms-windows-containers-revisited/)
