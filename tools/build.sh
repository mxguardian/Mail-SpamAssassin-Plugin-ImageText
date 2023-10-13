#!/usr/bin/env bash
# Update the README.md file
pod2markdown lib/Mail/SpamAssassin/Plugin/ImageText.pm >README.md
# Run the tests
prove -l t/*.t
