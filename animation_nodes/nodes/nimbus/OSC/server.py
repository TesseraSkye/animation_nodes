####################
# import pyosc so future imports are easier
# from....libs it the library at top level
from ....libs.PythonOSC import pythonosc
# import the server resources from the osc module
from pythonosc import osc_server, dispatcher
# import the resources for the killer client
from pythonosc import udp_client

# import for up-list of osc servers.
from .server_list import up_tools

# std lib imports
import argparse
from threading import Thread
####################


####DECLARATIONS####
a_parser = argparse.ArgumentParser()
disp = dispatcher.Dispatcher()
####################

########ARGS########
a_parser.add_argument(
    "--ip",
    default="127.0.0.1",
    help="The ip the server listens on.",
)
a_parser.add_argument(
    "--port",
    type=int,
    default=5505,
    help="The port the server listens on.",
)
args = a_parser.parse_args()
####################

########VARS########
# The address that the server is currently running on. Should never be changed.
up_address = [None, None]  # [next_address[0], next_address[1]]
# The next address the server will use. This is what the user sees.
next_address = [None, None]
# A unique address created when the server is started, and destroyed when it is killed. Used for internal addressing.
server_uid = None
# The threading osc server's 'object address'.
server = None
# The thread's 'object address'. The server is always run in a seperate thread so it doesn't block.
thread = None
# The uclient's 'object address' used to send the kill signal to the osc server
killer_client = None
####################

#####DISPATCHER#####
# Sets up dispatcher, which is used to map commands.


class Dispatch():
    def printAll(unused_addr, text):
        print(text)

# The shutdown routine used to stop the server. Has stopcodes, default safe is 0.
    def shutdown(unused_addr, code):

        stop_code_def = StopCode.getStopCodeDef(code)
        print(

            """
            Shutdown requested with stop code {0}.\n
            Code {0}: {1}\n
            Terminating...
            """.format(code, StopCode.getStopCodeDef(code))
        )


class StopCode():

    code_dict = {  # Use this to set up mapings

        "0": "Closed normally."

    }

    def getStopCodeDef(stop_code):
        stop_code = str(stop_code)
        try:
            return StopCode.code_dict[stop_code]
        except KeyError:
            return "Stop code does not exist."

# mapping happens here
# disp.map("/nimbus", Dispatch.printAll)#placeholder


########
# Redirect for server shutdown.
disp.map(
    "/nimbus/server/{server_identifier}/stop".format(server_uid), Dispatch.shutdown)
####################
