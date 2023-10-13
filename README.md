# NAME

Mail::SpamAssassin::Plugin::ImageText - SpamAssassin plugin to match text in images

# SYNOPSIS

    loadplugin Mail::SpamAssassin::Plugin::ImageText

    imagetext RULE_NAME /pattern/modifiers

# DESCRIPTION

This plugin allows you to write rules that match text in images. The text must be extracted
from the image by another plugin, such as [Mail::SpamAssassin::Plugin::ExtractText](https://metacpan.org/pod/Mail%3A%3ASpamAssassin%3A%3APlugin%3A%3AExtractText)

# AUTHORS

Kent Oyer <kent@mxguardian.net>

# COPYRIGHT AND LICENSE

Copyright (C) 2023 MXGuardian LLC

This is free software; you can redistribute it and/or modify it under
the terms of the Apache License 2.0. See the LICENSE file included
with this distribution for more information.

This plugin is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
