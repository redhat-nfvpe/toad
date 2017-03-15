# toad

[![Build Status](https://travis-ci.org/redhat-nfvpe/toad.svg?branch=master)](https://travis-ci.org/redhat-nfvpe/toad)

![toad_logo][toad_logo]

TOAD (TripleO Automated Deployer) is a system that helps automate various
OpenStack deployment scenarios using [TripleO
Quickstart](https://github.com/openstack/tripleo-quickstart).

In conjunction with Jenkins Job Builder and Jenkins, various scenarios and 
topologies can be scripted and then triggered via the Jenkins dashboard.

TOAD is used as a simple spin-up environment to bootstrap a testing
infrastructure with the ability to run tests with TripleO Quickstart, and parse
logs and write data into an ELK stack for data visualization.

Find below an image of how the general workflow happens within TOAD:

![TOAD Workflow][toad_workflow]

# Documentation

Documentation for TOAD can be found at [Read The
Docs](http://toad.rtfd.io)

[//]: # (vim: set filetype=markdown:expandtab)
[toad_logo]: doc/source/toad_logo.png
[toad_workflow]: https://raw.githubusercontent.com/redhat-nfvpe/toad/master/TOAD_Workflow.png
