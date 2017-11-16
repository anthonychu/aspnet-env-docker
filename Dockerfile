FROM microsoft/aspnet:4.7.1-windowsservercore-1709

WORKDIR /
RUN $ProgressPreference = 'SilentlyContinue'; \
    Invoke-WebRequest https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -OutFile \Windows\nuget.exe; \
    $ProgressPreference = 'Continue'; \
    \Windows\nuget.exe install WebConfigTransformRunner -Version 1.0.0.1

RUN md c:\aspnet-startup
COPY . c:/aspnet-startup
ENTRYPOINT ["powershell.exe", "c:\\aspnet-startup\\Startup.ps1"]
