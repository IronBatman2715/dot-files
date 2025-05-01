#!/bin/bash
#
# Some systems do not load ~/.profile automatically, but do load this file (~/.bash_profile).
# So, simply load ~/.profile from here to support those systems.

. "$HOME/.profile"
