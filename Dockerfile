FROM microsoft/aspnet:4.7.1-windowsservercore-1709
RUN md c:\aspnet-startup
COPY . c:/aspnet-startup
ENTRYPOINT ["powershell.exe", "c:\\aspnet-startup\\Startup.ps1"]
