#!/usr/bin/env python

"""
Reads the xml rules files and attempts to generate equivalent action rules for privoxy.

XML interpreted according to
https://www.eff.org/https-everywhere/rulesets but git
src/chrome/content/rules has rules with additional options (grep for
match_rule, for example), so maybe that page is out of date.

Copyright 2012 James Vasile
Released under GPLv3 or later
"""

import os, sys

rule_dir = "vendor/https-everywhere-release/chrome/content/rules"
if not os.path.exists(rule_dir):
    rule_dir = "vendor/https-everywhere/src/chrome/content/rules"
#rule_dir = "vendor/https-everywhere/src/chrome/content/rules"

from BeautifulSoup import BeautifulSoup
from lxml import etree


class UnknownRulesetAttribute(Exception):
    def __init__(self, args):
        self.xml, self.element, self.key = args

    def __str__(self):
        return "%s = %s" % (self.key, self.element.attrib[self.key])

class UnknownTargetAttribute(Exception):
    def __init__(self, args):
        self.xml, self.element, self.key = args
    def __str__(self):
        return "%s = %s" % (self.key, self.element.attrib[self.key])

custom = {
    "Crucial.com (partial)": {"^http://www\.crucial\.com/(images\d{0,2}|js|css|reviews)/":"^http://www\.crucial\.com/(images\d*|js|css|reviews)/"},
    "Epson.com (partial)":{"^https://(www\.)?epson\.com/(([a-zA-Z]([a-zA-Z0-9])+){1})$":"^https://(www\.)?epson\.com/(([a-zA-Z]([a-zA-Z0-9])+))$"},
    "MoveOn":{"^https?://civic\.moveon\.org/([a-z0-9]+){1}/{2,}":"^https?://civic\.moveon\.org/([a-z0-9]+)/+",
              "^http://(?:www\.)?moveon\.org/(([^a-z0-9]+)|([a-z0-9]{2,}\?)|([a-qs-z0-9]\?)|([a-z0-9]+[^a-z0-9?]+)){1}":
                  "^http://(?:www\.)?moveon\.org/(([^a-z0-9]+)|([a-z0-9]+\?)|([a-qs-z0-9]\?)|([a-z0-9]+[^a-z0-9?]+))",
              "^http://(pol|civ)\.moveon\.org/([^a-z0-9]+|([a-z0-9]+[^a-z0-9]+)|$){1}":
                  "^http://(pol|civ)\.moveon\.org/([^a-z0-9]+|([a-z0-9]+[^a-z0-9]+)|$)",
              "^http://civic\.moveon\.org/(([^a-z0-9]+)|([a-z0-9]+[^a-z0-9/]+)|([a-z0-9]+/($|[^/]+))|$){1}":
                  "^http://civic\.moveon\.org/(([^a-z0-9]+)|([a-z0-9]+[^a-z0-9/]+)|([a-z0-9]+/($|[^/]+))|$)"
              },
    "Kintera Network":{"^http://([-a-zA-Z0-9_]+\.)?([-a-zA-Z0-9_]+)\.kintera\.org/([^/]+/[^/]){1}":
                           "^http://([-a-zA-Z0-9_]+\.)?([-a-zA-Z0-9_]+)\.kintera\.org/([^/]+/[^/])"
        }

    }

def cleanup(name, att):
    if name in custom and att in custom[name]:
        return custom[name][att]
    else:
        for c in "#@":
            att = att.replace(c, r"\%s" % c)
        return att

def translate_ruleset(xml):
    def do_rule(element):
        for k in element.attrib.keys():
            if k == 'default_off':
                return
            elif k == 'name':
                name = element.attrib[k]
            elif k == "match_rule":
                sys.stderr.write("Warning: match_rule attribute encountered in %s\n" % name)
            elif k == "platform":
                sys.stderr.write("Warning: platform rule encountered in %s\n" % name)
            else:
                raise UnknownRulesetAttribute, [xml, element, k]

        target = []
        for target_element in element.iter("target"):
            if not 'default_off' in target_element.attrib:
                target.append(target_element.attrib['host'])
            for k in target_element.attrib.keys():
                if k != 'host' and k != 'default_off':
                    raise UnknownTargetAttribute, target_element
        if not target:
            sys.stderr.write("Warning: no target for %s\n" % name)
            return
    
        print "#", name.encode("UTF-8")
        red_str = "{+redirect{"
        for rule_element in element.iter("rule"):
            red_str +=("s@%s@%s@" % (cleanup(name, rule_element.attrib['from']),
                                     cleanup(name, rule_element.attrib['to']))
                       +"\t"
                       ).encode("UTF-8")
        red_str = red_str.strip()
        print"%s}}" % red_str
        for t in target:
            print t.encode("UTF-8")
        print

    try:
        xml = xml.replace("rule from host", "rule from")
        root = etree.XML(xml)
    except:
        print xml
        raise

    for element in root.iter("rulesetlibrary"):
        for elem in element.iter("ruleset"):
            do_rule(elem)
        return

    for element in root.iter("ruleset"):
        do_rule(element)

def main(rule_dir=rule_dir):
    default_ruleset = os.path.join(rule_dir, "default.rulesets")
    if os.path.exists(default_ruleset):
        with open(default_ruleset, 'r') as INF:
            translate_ruleset(INF.read())
    else:
        for fname in os.listdir(rule_dir):
            if fname.endswith('.xml'):
                with open(os.path.join(rule_dir, fname), 'r') as INF:
                    translate_ruleset(INF.read())


if __name__ == "__main__":
    main()
