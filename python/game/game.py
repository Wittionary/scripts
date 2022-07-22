# MVP:
# - create 2 commands
# - set env vars
# - get time delta
# show progress in terminal

import os, click
from datetime import datetime, date

# VERBS?
# get
# show
# list
# buy

# NOUNS?
# status / stats --- show score/resources
# clickers --- show "clicks" per second (or minute?)
# upgrades
# map / location
# config / game

@click.group()
def cli():
    pass

@click.command()
@click.option('--name', help='Name of the script or *.exe', type=str)
@click.option('--id', help='Id of the script', type=int)
def run(name, id):
    """
    This runs an existing script in the repo/library.
    """


# get time
def get_time():
    now = datetime.now()
    return now

# store time
# https://betterprogramming.pub/lightweight-efficient-database-alternatives-for-python-bb990eee752

# get delta
def get_time_delta(then):
    delta = datetime.now() - then
    return delta





cli.add_command(run)
cli.add_command(hello)
cli.add_command(auth)

cli.add_command(template_command)

if __name__ == '__main__':
    cli()