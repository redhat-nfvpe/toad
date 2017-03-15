Welcome to the documentation for TOAD!
======================================

Project Overview
----------------

TOAD (TripleO Automated Deployer) is a system that helps automate various
OpenStack deployment scenarios using `TripleO
Quickstart <https://github.com/openstack/tripleo-quickstart>`_.

In conjunction with Jenkins Job Builder and Jenkins, various scenarios and 
topologies can be scripted and then triggered via the Jenkins dashboard.

TOAD is used as a simple spin-up environment to bootstrap a testing
infrastructure with the ability to run tests with TripleO Quickstart, and parse
logs and write data into an ELK stack for data visualization.

Find below an image of how the general workflow happens within TOAD:

.. image:: ../../TOAD_Workflow.png


Get The Code
------------

The `source <https://github.com/redhat-nfvpe/toad>`_ is available on GitHub.

Contents
--------

.. toctree::
   :maxdepth: 2
   :glob:

   quickstart
   tracking_development
   requirements
   deployment
   overrides
