import do_stuff

from vantage6.client import Client

# create a client and autenticate
client = Client(...)
client.authenaticate(...)

# create task for algorithm
client.task.create(...)

# poll for results
ready = False
while not ready:
    do_stuff()
