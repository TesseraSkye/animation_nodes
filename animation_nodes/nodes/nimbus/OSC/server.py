# pythonosc
from pythonosc import osc_server, dispatcher
from pythonosc import udp_client

# import the server list tools
from .server_list import up_tools  # pylint: disable=E0401 ###most useful thing! Disables module finding bug present in pylint


# std lib imports
####
import argparse
from threading import Thread
import time

# Node imports
import bpy

from ....events import propertyChanged
from ....base_types import AnimationNode
####

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
uid = None
# The threading osc server's 'object address'.
server = None
# The thread's 'object address'. The server is always run in a seperate thread so it doesn't block.
thread = None
# The uclient's 'object address' used to send the kill signal to the osc server
killer_client = None
####################

#####DISPATCHER#####
# Sets up dispatcher, which is used to map commands.

####
s_codes = {  # Use this to set up mapings

    "0": "Closed normally."

}
####


def getStopCodeDef(stop_code):
    stop_code = str(stop_code)
    try:
        return s_codes[stop_code]
    except KeyError:
        return "Stop code does not exist."


# The shutdown routine used to stop the server. Has stopcodes, default safe is 0.


def dispShutdown(unused_addr, code):
    print(
        """
        Shutdown requested with stop code {0}.\n
        Code {0}: {1}\n
        Terminating...
        """.format(code, getStopCodeDef(code))
    )

#########ADDRESSING#########


def setAddress(ip="", port=""):
    """
    Sets defaults which are used the next time the server is started.\n
    usage: set(ip (str), port (int))\n
    if None is entered, it defaults to\n
    an ip of '127.0.0.1' and a port of 5505.\n
    if one or both of the arguments is left blank,\n
    that parameter will remain unchanged.
    """

    global next_address

    try:
        port = int(port)
    except ValueError:
        pass

    if ip == None:
        next_address[0] = args.ip
    if port == None:
        next_address[1] = args.port
    if ip == "":
        pass
    if port == "":
        pass
    if ip != None and ip != "":
        next_address[0] = ip
    if port != None and port != "":
        next_address[1] = port


def getNextAddress(call):
    """
    Gets the next address
    that will be used to start the server.
    Args can be 'ip' and / or 'port'.\n
    Returns None if server is not online.
    """
    global next_address

    call = str(call)
    call = call.lower()
    print(call)
    output = []

    if "ip" in call:
        output.append(next_address[0])
    if "port" in (call):
        output.append(next_address[1])
    if not "ip" or "port" in call:
        print(
            """
            No valid address selector listed!\n
            Args can be 'ip' and / or 'port'.
            """,
        )
        return None
    return output


def getCurrentAddress(call):
    """
    Gets the address of the running server, if anything.
    Args can be 'ip' and / or 'port'.\n
    Returns None if server is not online.
    """
    global up_address

    call = str(call)
    call = call.lower()
    print(call)
    output = []

    if isUp() == True:
        if "ip" in call:
            output.append(up_address[0])
        if "port" in (call):
            output.append(up_address[1])
        if not "ip" or "port" in call:
            print(
                """
                No valid address selector listed!\n
                Args can be 'ip' and or 'port'.
                """,
            )
        return output

    if isUp() != True:
        print("Server not running!")
        return None


def getAddress(text=""):
    """
    Shortener function for getCurrent()
    """
    return getCurrentAddress(text)

############################


#########FUNCTIONS##########

def isUp():
    global thread
    try:
        up_status = thread.is_alive()
        return up_status
    except AttributeError:
        print("thread doesn't point to anything! Is the server initialised?")


def start():
    """
    This starts the OSC Server. It has no usable derivatives. \n
    Can not be run if server is already up, will return False.\n
    Takes no arguments.\n
    Returns, as a list:\n
    ..The server's status as a boolean\n
    ..The Unique Identifier as an int\n
    ..The ip and port as a nested list
    """
    global uid
    global disp
    global server
    global thread
    global up_address
    global next_address

    temp_up_status = isUp()
    if temp_up_status != True:
        if next_address[0] == None:
            # antiquated, but can protect in case of bad things
            next_address[0] = args.ip
        if next_address[1] == None:
            # antiquated, but can protect in case of bad things
            next_address[1] = args.port

        server = None  # just in case...
        thread = None  # ^ ditto

        # this is done here so that the UID can be generated in time for the dispatcher to pick up on it.
        print("Binding current ip and port to up_address[0, 1]..")
        up_address[0] = next_address[0]
        up_address[1] = next_address[1]

        print("Adding address to up_list..")
        uid = up_tools.pushAddress(up_address)

        ########
        print(
            "seting up stop command as '/nimbus/server/{server_identifier}/stop'".format(uid))
        # Redirect for server shutdown.
        disp.map(
            "/nimbus/server/{server_identifier}/stop".format(uid), dispShutdown)
        ########

        server = osc_server.ThreadingOSCUDPServer(
            (next_address[0], next_address[1]),
            disp,
        )

        thread = Thread(
            # Calling it this way forces it to either work, or throw an exception.
            target=server.serve_forever,  # No maybe!
            name="nimbus_osc_server",
            daemon=True,
        )
        print("Starting Server!")
        thread.start()

        return [isUp(), uid, up_address]

    elif isUp() == True:
        print("Server already running!")


def stop(stop_code=0):
    """
    Used to kill the running server.\n
    Usage: stop(stop_code = 0)
    """
    global up_address
    global uid

    if server != None:
        if isUp() == True:
            killer_client = udp_client.SimpleUDPClient(
                up_address[0], up_address[1])
            print("Sending Kill Signal to server on {0}...".format(
                up_address[0] + up_address[1]))
            killer_client.send_message(
                "/nimbus/server/{server_identifier}/stop".format(uid), str(stop_code))
            if isUp() == True:  # checks that the server actually stopped
                time.sleep(1)
                raise Exception("STOP FAILURE", "Server failed to stop!")
        elif isUp() == False:
            print("Server is already stopped.")
        return isUp()
    elif server == None:
        print("Server has never been started!")


############NODE############
class OSCServerNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_OSCServerNode"
    bl_label = "OSC Server"

    onOffState = bpy.props.EnumProperty(  # on - off toggle
        items=[
            ("off", "Off", "Server State: Off"),
            ("on", "On", "Server State: On"),
        ],
        name="Server State",
        description="Toggle the server's state",
        default="off",
        options={"SKIP_SAVE"},
        update=propertyChanged,
    )

    setIp = bpy.props.StringProperty(  # ip
        name="Serving Ip",
        description="""
               The ip address used when starting the server.\n
               Don't use an IP over 126.255.255.255 except for lopback.\n
               Loopback (internal only) starts at 127.0.0.1, which is the default value.\n
                        """,
        default="127.0.0.1",
        maxlen=15,
        options={"SKIP_SAVE"},
        update=propertyChanged,
    )
    setPort = bpy.props.IntProperty(  # port
        name="Serving port",
        description="""
                The port used when starting the server.\n
                Integer from 1 to 65535.\n
                Defaults to 5505.\n
                """,
        default=5505,
        min=1,
        max=65535,
        soft_min=1,
        soft_max=65535,
        options={"SKIP_SAVE"},
        update=propertyChanged,
    )

    def create(self):
        pass

    def draw(self, layout):
        layout.prop(self, "onOffState")
        layout.prop(self, "setIp")
        layout.prop(self, "setPort")

    def execute(self):

        if self.onOffState.off:
            stop()

        if self.onOffState.on:
            start()

        if self.setIp:
            print("IP!")

        if self.setPort:
            print("PORT!!")


############################
############################
# General registration for most modules
if __name__ == "__main__":
    import os
    import sys
    from os.path import dirname, join, abspath, basename
    # temporarily sets main package at current location, so that it can be itterated.
    parent_dir = dirname(abspath(__file__))
    main_package = parent_dir
    # Iterates until it finds nimbus_vis or has run 10 times #10 subdirs max
    iter = 0
    #
    while basename(main_package) != "animation_nodes" and iter in range(10):
        main_package = dirname(main_package)
        iter = iter + 1
    #
    if not main_package in sys.path:
        sys.path.append(main_package)
        print(main_package + " appended to sys path")
    #
    library = join(main_package, "nimbus_libs")
    #
    if not library in sys.path:
        sys.path.append(library)
        print(library + " appended to sys path")
    #
