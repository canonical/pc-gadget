# Security policy

The release model of the pc snap is following rolling releases. 

The pc snap is a gadget snap that contains the bootloader assets required for booting
an Ubuntu Core system. Most of the files contained in this repository are configuration files
used for system initialization. As such these files can be sensitive and must be treated
carefully. Most of the files published with this snap are sourced from the Ubuntu archives 
and as such must adhere to same security policies as established for upstream.

## Supported versions
When reporting security issues against the pc snap, only the latest 
release of the pc snap is supported. Using the newest revision of this gadget snap is
recommendation.

The pc snap receives intermittent releases determined by upstream changes. There are two 
types of security fixes that can be shipped with new versions of the pc snap.

- Security fixes that are relevant to the files inside this repository
- Security fixes related to the packages sourced from the official APT archives.

## What qualifies as a security issue

Any vulnerability that allows the pc snap to interfere outside of the intended 
restrictions qualifies as a security issue, including vulnerabilities that
allows an unprivileged user on the local system to escalate privileges or cause a 
denial of service etc due to the use of the contents of the pc snap on the system.

## Reporting a vulnerability

The easiest way to report a security issue is through
[GitHub](https://github.com/canonical/pc-gadget/security/advisories/new). See
[Privately reporting a security
vulnerability](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing/privately-reporting-a-security-vulnerability)
for instructions.

The Ubuntu Core GitHub admins will be notified of the issue and will work with you
to determine whether the issue qualifies as a security issue and, if so, in
which component. We will then handle figuring out a fix, getting a CVE
assigned and coordinating the release of the fix to the pc snap.

The [Ubuntu Security disclosure and embargo
policy](https://ubuntu.com/security/disclosure-policy) contains more
information about what you can expect when you contact us, and what we
expect from you.
