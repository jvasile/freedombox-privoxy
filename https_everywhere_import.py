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

rule_dir = "vendor/https-everywhere/src/chrome/content/rules"

import os, sys
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
        return att.replace("#", r"\#")

def translate_ruleset(xml):
    try:
        root = etree.XML(xml)
    except:
        print xml
        raise

    for element in root.iter("ruleset"):
        for k in element.attrib.keys():
            if k == 'default_off':
                return
            elif k == 'name':
                name = element.attrib[k]
            elif k == "match_rule":
                print "Warning: match_rule attribute encountered"
            else:
                raise UnknownRulesetAttribute, [xml, element, k]

    target = []
    for element in root.iter("target"):
        if not 'default_off' in element.attrib:
            target.append(element.attrib['host'])
        for k in element.attrib.keys():
            if k != 'host' and k != 'default_off':
                raise UnknownTargetAttribute, element
    if not target:
        return
    
    for element in root.iter("rule"):
        print "#", name.encode("UTF-8")
        print (r"{+redirect{s@%s@%s@}}" % (cleanup(name, element.attrib['from']),
                                           cleanup(name, element.attrib['to'])
                                           )).encode("UTF-8")
        for t in target:
            print t.encode("UTF-8")
        print

def main(rule_dir=rule_dir):
    for fname in os.listdir(rule_dir):
        if fname.endswith('.xml'):
            with open(os.path.join(rule_dir, fname), 'r') as INF:
                translate_ruleset(INF.read())


if __name__ == "__main__":
    main()
