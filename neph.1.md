neph 1 "February 2018" neph "User Manual"
=========================================

# NAME
neph - a command line job processor

# SYNOPSIS
**neph** [**--clean** | **--help** | **--version**]  
**neph** [**--yaml**=*<file>*] [**--mode**=*CI*|*NORMAL*|*QUIET*] [**job_name**]

# DESCRIPTION
Neph is a command line job processor which can execute jobs concurrently, and can be substitution for **make**.  
It isn't ready yet, incompatible changes may appear in each release. See **INCOMPATIBLE CHANGES** section.

# OPTIONS
**-y** *FILE*, **--yaml** *FILE*
  Specify a location of neph.yaml (Default is neph.yaml)

**-m** *MODE*, **--mode** *MODE*
  Output mode. Values can be
      - *AUTO* (default)   Automatically set output mode: if output is a terminal, it will be *NORMAL*, if it is a pipe, it will be *CI*
      - *NORMAL*           This mode shows each job in a tree structure, and a progress bar for the entire process.
      - *CI*               This mode only prints if a job is started, or finished.
      - *QUIET*            Don't output anything.

**-c**, **--clean** Clean caches

**-v**, **--version** Software version.

**-h**, **--help** Show a help message.

# INCOMPATIBLE CHANGES
**0.1.18**
  - The *-j | --job* option were removed. Job names can be specified without an option: **neph** [*job_name*]
  - The *clean* action were moved to *--clean*.
  - The *uninstall* action were removed.

# AUTHORS
Originally written by Taichiro Suzuki.  
Maintained by Taichiro Suzuki and Márton Szabó.
