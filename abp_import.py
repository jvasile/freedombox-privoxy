#!/usr/bin/env python

"""
Script to translate easyprivacy list into rules for privoxy.

James Vasile
"""

import sys

easylist_url = "todo: put url here"
easyprivacy_url = "todo: put url here"


def out(*args):
    for a in args:
        sys.stdout.write(a)
    if len(args) >= 1 and args[0] != "":
        print

def clean_pattern(pat):
    return pat

def clean_rule(rule):
    if rule.startswith("/") and rule.endswith("/"):
        return clean_pattern(rule)
    rule = (rule
            .replace("?", r"\?")
            .replace("^", "[/:=?&]")
            .replace("||", "^")
            )
    if rule.startswith("|"):
        rule = "^"+rule[1:]
    if rule.endswith("|"):
        rule = rule[:-1] + "$"

    if rule:
        return rule + "\n"

def ignore_opt(pat, opts, opt):
    new_opts = [o for o in opts if o != opt]
    if new_opts:
        return translate(pat+"$"+','.join(new_opts))
    else:
        return translate(pat)
    return ""

def translate(line):
    if line.startswith("!"):
        return( "#%s\n" % line[1:])
    elif line.startswith("@@"):
        unblock.append(line[2:])
    elif '$' in line:
        pat, opts = line.split("$",2) 
        opts = opts.split(',')
        for opt in opts:
            if opt in "third-party|~third-party|script|image":
                return ignore_opt(pat, opts, opt)

        sys.stderr.write("Unhandled options: "+', '.join(opts) + "\n")
    elif '##' in line:
        filter.append(line)
    else:
        return(clean_rule(line))
    return ""

def translate_all(easylist, infile):
    str = ""
    for line in easylist:
        line = line.strip()
        str += translate(line)


    str += "{-block{%s}}\n" % infile
    for line in unblock:    
        str += translate(line)

    return str

unblock = []
filter = [] # todo: convert ## commands into filters
def main():
    if len(sys.argv) < 2:
        print "Must specify filename of ad block plus rules file to process."
        print "You can get those lists from:"
        print easylist_url
        print easyprivacy_url
        sys.exit()
    else:
        infile = sys.argv[1]

    with open(infile, 'r') as INF:
        easylist = INF.readlines()

    print "{+block{%s}}" % infile

    easylist[0] = "! "+ easylist[0]
    print translate_all(easylist, infile)

if __name__ == "__main__":
    main()

