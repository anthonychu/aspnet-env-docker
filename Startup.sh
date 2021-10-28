#!/bin/bash
PROJECT_NAME=Your_project_name.dll
/app/Set-WebConfigSettings.sh /app/$PROJECT_NAME.config

dotnet $PROJECT_NAME
