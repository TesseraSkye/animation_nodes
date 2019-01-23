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

############NODE############


class OSCServerNode(bpy.types.Node, AnimationNode):
    bl_idname = "an_OSCServerNode"
    bl_label = "OSC Server"

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

    ######VARS######
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
    ################

    #####DISPATCHER#####
    # Sets up dispatcher, which is used to map commands.

    ####
    s_codes = {  # Use this to set up mapings

        "0": "Closed normally."

    }
    ####

    def getStopCodeDef(self, stop_code):
        stop_code = str(stop_code)
        try:
            return self.s_codes[stop_code]
        except KeyError:
            return "Stop code does not exist."

    # The shutdown routine used to stop the server. Has stopcodes, default safe is 0.

    def dispShutdown(self, unused_addr, code):
        self.server.shutdown()
        print([self.server, self.thread])
        print(
            """
            Server {2} on {3} recieved kill code.\n
            Shutdown requested with stop code {0}.\n
            Code {0}: {1}\n
            Terminating...
            """.format(code, self.getStopCodeDef(code), up_tools.getUID(self.up_address), self.up_address)
        )
        self.thread.join(timeout=0.8)
        if self.thread.is_alive == False:
            print("Server {} has been stopped!").format(
                up_tools.pullAddress(self.up_address))
        if self.thread.is_alive == True:  # checks that the server actually stopped
            raise Exception("Looks like the server failed to stop!")

    #########ADDRESSING#########

    def setAddress(self, ip="", port=""):
        """
        Sets defaults which are used the next time the server is started.\n
        usage: set(ip (str), port (int))\n
        if None is entered, it defaults to\n
        an ip of '127.0.0.1' and a port of 5505.\n
        if one or both of the arguments is left blank,\n
        that parameter will remain unchanged.
        """

        try:
            port = int(port)
        except ValueError:
            pass

        if ip == None:
            self.next_address[0] = self.args.ip
        if port == None:
            self.next_address[1] = self.args.port
        if ip == "":
            pass
        if port == "":
            pass
        if ip != None and ip != "":
            self.next_address[0] = ip
        if port != None and port != "":
            self.next_address[1] = port

    def getNextAddress(self, call):
        """
        Gets the next address
        that will be used to start the server.
        Args can be 'ip' and / or 'port'.\n
        Returns None if server is not online.
        """

        call = str(call)
        call = call.lower()
        print(call)
        output = []

        if "ip" in call:
            output.append(self.next_address[0])
        if "port" in (call):
            output.append(self.next_address[1])
        if not "ip" or "port" in call:
            print(
                """
                No valid address selector listed!\n
                Args can be 'ip' and / or 'port'.
                """,
            )
            return None
        return output

    def getCurrentAddress(self, call):
        """
        Gets the address of the running server, if anything.
        Args can be 'ip' and / or 'port'.\n
        Returns None if server is not online.
        """

        call = str(call)
        call = call.lower()
        print(call)
        output = []

        if self.isUp() == True:
            if "ip" in call:
                output.append(self.up_address[0])
            if "port" in (call):
                output.append(self.up_address[1])
            if not "ip" or "port" in call:
                print(
                    """
                    No valid address selector listed!\n
                    Args can be 'ip' and or 'port'.
                    """,
                )
            return output

        if self.isUp() != True:
            print("Server not running!")
            return None

    def getAddress(self, text=""):
        """
        Shortener function for getCurrentAddress()
        """
        return self.getCurrentAddress(text)

    ################

    #########FUNCTIONS##########

    def isUp(self):
        """
        Checks if the server is up.\n
        Usage: isUp(self)\n
        Returns boolean.
        """

        try:
            up_status = self.thread.is_alive()
            return up_status
        except AttributeError:
            print("thread doesn't point to anything! Is the server initialised?")

    def start(self):
        """
        This starts the OSC Server. It has no usable derivatives. \n
        Can not be run if server is already up, will return False.\n
        Usage: start(self)\n
        Returns, as a list:\n
        ..The server's status as a boolean\n
        ..The Unique Identifier as an int\n
        ..The ip and port as a nested list
        """

        print(self)

        temp_up_status = self.isUp()
        if temp_up_status == False or temp_up_status == None:
            if self.next_address[0] == None:
                # antiquated, but can protect in case of bad things
                self.next_address[0] = self.args.ip
            if self.next_address[1] == None:
                # antiquated, but can protect in case of bad things
                self.next_address[1] = self.args.port

            self.server = None  # just in case...
            self.thread = None  # ^ ditto

            # this is done here so that the UID can be generated in time for the dispatcher to pick up on it.
            print("Binding current ip and port to up_address[0, 1]..")
            self.up_address[0] = self.next_address[0]
            self.up_address[1] = self.next_address[1]

            print("Adding address to up_list..")
            self.uid = up_tools.pushAddress(self.up_address)

            ########
            kill_code = "/blender/oscserver/{0}/stop".format(self.uid)
            print(
                "seting up stop command as {0}".format(kill_code))
            # Redirect for server shutdown.
            self.disp.map(kill_code, self.dispShutdown)
            ########

            self.server = osc_server.ThreadingOSCUDPServer(
                (self.next_address[0], self.next_address[1]),
                self.disp,
            )

            self.thread = Thread(
                # Calling it this way forces it to either work, or throw an exception.
                target=self.server.serve_forever,  # No maybe!
                name="nimbus_osc_server",
                daemon=True,
            )

            print(self.server)

            print("Starting Server!")
            self.thread.start()

            print([self.isUp(), self.uid, self.up_address])

            return [self.isUp(), self.uid, self.up_address]

        elif temp_up_status == True:
            print("Server already running!")

    def stop(self, stop_code=0):
        """
        Used to kill the running server.\n
        Usage: stop(stop_code = 0)\n
        Returns self.isUp()
        """
        if self.server != None:
            self.killer_client = udp_client.SimpleUDPClient(
                self.up_address[0], self.up_address[1])
            print(
                "Sending Kill Signal to server on {0} with UID {1}...".format(
                    [self.up_address[0], self.up_address[1]],
                    up_tools.getUID(self.up_address),
                ),
            )
            self.killer_client.send_message(
                "/blender/oscserver/{0}/stop".format(up_tools.getUID(self.up_address)), str(stop_code))
            ####
            time.sleep(1)
            # checks that the server actually stopped
            if up_tools.getUID(self.up_address) != None:
                raise Exception("STOP FAILURE", "Server failed to stop!")
        else:
            print("Server doesn't appear to have been started!")
        ############################################

    #############################

    #####SPEC######
    def setState(self, context):
        if self.state == "on":
            self.start()

        elif self.state == "off":
            self.stop()

    def setIp(self, context):
        self.setAddress(self.propIp)
        self.stop()

    def setPort(self, context):
        self.setAddress("", self.propPort)
        self.stop()
    ###############

    state = bpy.props.EnumProperty(  # on - off toggle
        items=[
            ("off", "Off", "Server State: Off"),
            ("on", "On", "Server State: On"),
        ],
        name="Server State",
        description="Toggle the server's state",
        default="off",
        options={"SKIP_SAVE"},
        update=setState,
    )

    propIp = bpy.props.StringProperty(  # ip
        name="IP",
        description="""
               The ip address used when starting the server.\n
               Don't use an IP over 126.255.255.255 except for lopback.\n
               Loopback (internal only) starts at 127.0.0.1, which is the default value.\n
                        """,
        default="127.0.0.1",
        maxlen=15,
        options={"SKIP_SAVE"},
        update=setIp,
    )
    propPort = bpy.props.IntProperty(  # port
        name="PORT",
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
        update=setPort,
    )

    def create(self):
        pass

    def draw(self, layout):
        layout.prop(self, "state")
        layout.prop(self, "propIp")
        layout.prop(self, "propPort")

    def execute(self):
        pass


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
