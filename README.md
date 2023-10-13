# NAME

Mail::SpamAssassin::Plugin::ImageText - SpamAssassin plugin to match text in images

# SYNOPSIS

    loadplugin Mail::SpamAssassin::Plugin::ImageText

    imagetext RULE_NAME /pattern/modifiers

# DESCRIPTION

This plugin allows you to write rules that match text in images. The text must be extracted
from the image by another plugin, such as [Mail::SpamAssassin::Plugin::ExtractText](https://metacpan.org/pod/Mail%3A%3ASpamAssassin%3A%3APlugin%3A%3AExtractText)
