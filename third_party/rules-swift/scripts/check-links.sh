#!/bin/sh
# Validate repository-relative Markdown links that name a path or file.
set -eu

ROOT=${RULES_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}

if ! command -v perl >/dev/null 2>&1; then
    echo "link gate: perl is required" >&2
    exit 1
fi

find "$ROOT" -type f -name '*.md' -not -path '*/.git/*' -not -path '*/.build/*' -print0 \
    | xargs -0 perl -MFile::Basename=dirname -MFile::Spec -e '
        use strict;
        use warnings;
        my @broken;

        sub check_target {
            my ($file, $target) = @_;
            $target =~ s/\s+"[^"]*"$//;
            $target =~ s/^<|>$//g;
            return if $target eq q{} || $target =~ m{^(?:#|/|[A-Za-z][A-Za-z0-9+.-]*:)};
            $target =~ s/[#?].*$//;
            $target =~ s/%20/ /g;
            my $path = File::Spec->rel2abs($target, dirname($file));
            push @broken, "$file -> $target" unless -e $path;
        }

        for my $file (@ARGV) {
            open my $handle, "<", $file or die "$file: $!";
            local $/;
            my $text = <$handle>;
            # Examples are not navigable links. Remove fenced and inline code before
            # interpreting Markdown link syntax.
            $text =~ s{^[ \t]*(```+|~~~+).*?^[ \t]*\1[ \t]*$}{}gms;
            $text =~ s{(`+)[^\n]*?\1}{}g;
            while ($text =~ /\[[^\]]*\]\(([^)]+)\)/g) {
                check_target($file, $1);
            }
            while ($text =~ /^\s{0,3}\[[^\]]+\]:\s*(\S+)/gm) {
                check_target($file, $1);
            }
        }
        if (@broken) {
            print "LINK FAIL (missing repository-relative targets):\n", join("\n", @broken), "\n";
            exit 1;
        }
    '

echo "link gate clean"
