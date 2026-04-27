@echo off
setlocal

set DIR=%~dp0

if "%JAVA_HOME%"=="" (
    set JAVA_EXE=java.exe
) else (
    set JAVA_EXE=%JAVA_HOME%\bin\java.exe
)

set CLASSPATH=%DIR%gradle\wrapper\gradle-wrapper.jar

"%JAVA_EXE%" -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*