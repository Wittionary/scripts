#!/usr/bin/env python
# Intake a series of CloudFormation templates and spit out a MermaidJS diagram on the order they should be deployed
import json
import sys
import os

#directory = sys.argv[1]
directory = "C:\Users\WittAllen\git\pg\pts-witt-scratchpad\carsaver\NT220207a - CarSaver AWS CloudFormation"
print(f"Template directory: {directory}")

# Get YAML files in directory

# Read the Outputs of each template
# Read the !ImportValues of each template
# Prioritize those with no !ImportValues as lower weight (happens sooner)
# 