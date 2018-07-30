neph 1 "Juny 2018" neph "User Manual"
=========================================

# NAME
neph - a command line job processor

# SYNOPSIS
**neph** [**job_name**]

# DESCRIPTION
Neph is a command line job processor which can execute jobs concurrently, and can be substitution for **make**.  
**Note:** It isn't ready yet, incompatible changes may appear in each release. See **INCOMPATIBLE CHANGES** section.

# OPTIONS

**-v**, **--version** Show software version.

**-h**, **--help** Show a help message.

# INCOMPATIBLE CHANGES
**0.1.18**
  - The *-j | --job* option were removed. Job names can be specified without an option: **neph** [*job_name*]
  - The *clean* action were moved to *--clean*.
  - The *uninstall* action were removed.  
**0.2.0**
  - *New file format introduced.* **The old file format is not supported.**

# AUTHORS
Originally written by Taichiro Suzuki.  
Maintained by Taichiro Suzuki and Márton Szabó.
