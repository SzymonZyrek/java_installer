# java_installer

> **Historical Java runtime installer**

A Bash utility written for the pre-modern-JDK-distribution era to discover, download and install Oracle JDK/JRE releases.

The script supported:

- fetching available versions;
- listing and filtering releases;
- installing selected JDK or JRE versions;
- choosing an installation directory;
- setting `JAVA_HOME`;
- configuring `update-alternatives`;
- temporary-work-directory cleanup and interactive prompts.

## Historical context

At the time, repeatedly setting up particular Java versions across Linux machines involved enough manual browser/download/configuration work that automating it was worthwhile.

The implementation contains assumptions specific to old Oracle download URLs, licensing cookies and JDK version formats. Those assumptions are intentionally not modernized here.

## Status

Historical tooling only. Do **not** use this as a current JDK installer; modern JDK distributions and package managers have made most of this workflow obsolete.
