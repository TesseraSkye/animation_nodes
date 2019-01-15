from random import random  # used for UIDs
up_list = {
    # UID: address
}

################


def validAddressFormat(address):
    if address[0] is str(address[0]) and address[1] is int(address[1]):
        pass
    else:
        raise SyntaxError

########


def checkForAddress(address):
    """
    checkForAddress(address)\n
    address = [ip, port]\n
    \n
    Returns boolean.
    """
    global up_list

    validAddressFormat(address)

    if address in up_list.values():
        return True
    elif not address in up_list.values():
        return False


def checkForUID(UID):
    """
    checkForAddress(address)\n
    address = [ip, port]\n
    \n
    Returns boolean.
    """
    global up_list

    if UID in up_list.keys():
        return True
    elif not UID in up_list.keys():
        return False

########


def pushAddress(address):
    """
    push(address)\n
    address = [ip, port]\n
    \n
    Pushes address to up_list.\n
    Returns the unique id of that server used to get or pull.\n
    Returns None if already in list.
    """
    global up_list

    def newUID():
        UID = int(random() * 100)
        while UID in up_list:
            UID = int(random() * 100)
        return UID

    validAddressFormat(address)

    if checkForAddress(address) == False:
        id = newUID()
        up_list.__setitem__(id, address)
        return id
    elif checkForAddress(address) == True:
        return None

########


def getUID(address):
    """
    getUID(address)\n
    Returns the UID associated with an address.\n
    Returns None if not in list.
    """
    global up_list

    validAddressFormat(address)

    # Looks for address in all UIDs
    output = [UID for UID, addr in up_list.items() if up_list[UID] == address]
    if output == []:
        return None
    else:
        return output


def getAddress(UID):
    global up_list
    return up_list[UID]

########


def pullAddress(address):
    """
    pullAddress(address)\n
    Returns the UID associated with the address,\n
    And removes the entry fron the list.\n
    Returns None if not in list.
    """
    global up_list

    validAddressFormat(address)

    output = getUID(address)
    if output == None:
        return output
    else:
        for index in output:
            del (up_list[output[index]])
        return output


def pullUID(UID):
    """
    pullUID(UID)\n
    Returns the address associated with the UID,\n
    And removes the entry fron the list.\n
    Returns None if not in list.
    """
    global up_list

    addr = getAddress(UID)
    if addr != None:
        del (up_list[UID])
        return addr
    else:
        return addr

########
