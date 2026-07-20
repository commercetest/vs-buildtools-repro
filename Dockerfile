# Minimal reproduction: does the Visual Studio Build Tools installer hang inside
# a Windows Server Core container?  BASE selects the image (see the workflow).
#
# On an affected base the RUN never returns: the bootstrapper self-extracts,
# then blocks waiting on a local RPC reply from its own setup engine (LpcReply,
# ~0 CPU, no network).  On an unaffected base it prints INSTALL COMPLETED.
ARG BASE
FROM ${BASE}

SHELL ["powershell", "-NonInteractive"]

RUN Invoke-WebRequest 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile C:\vs.exe ; \
    Start-Process -Wait -FilePath C:\vs.exe -ArgumentList \
      '--quiet','--wait','--norestart','--nocache', \
      '--add','Microsoft.VisualStudio.Component.VC.Tools.x86.x64', \
      '--installPath','C:\BuildTools' ; \
    Write-Output 'INSTALL COMPLETED'
