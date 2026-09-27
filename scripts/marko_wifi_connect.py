#!/usr/bin/env python3
"""One Wi-Fi activation with a scoped, non-interactive NetworkManager agent.

The request (including the optional password) travels over stdin, never argv.
The agent and activation share a D-Bus owner, so NetworkManager asks this client
first. Missing/rejected secrets cancel this attempt instead of opening another
desktop agent. NetworkManager owns and stores accepted PSKs.
"""

import asyncio
import contextlib
import json
import os
import signal
import sys
import uuid

from dbus_next import BusType, Message, MessageType, Variant
from dbus_next.aio import MessageBus
from dbus_next.errors import DBusError

NM = "org.freedesktop.NetworkManager"
ROOT = "/org/freedesktop/NetworkManager"
PROPERTIES = "org.freedesktop.DBus.Properties"
AGENT_PATH = ROOT + "/SecretAgent"
SECURITY = "802-11-wireless-security"


def value(settings, group, key, default=None):
    item = settings.get(group, {}).get(key)
    return item.value if item is not None else default


class ActivationAgent:
    def __init__(self, owner, target_uuid):
        self.owner = owner
        self.target_uuid = target_uuid
        self.needs_secret = False

    def handle(self, message):
        if (message.message_type != MessageType.METHOD_CALL
                or message.path != AGENT_PATH
                or message.interface != NM + ".SecretAgent"):
            return None
        if message.sender != self.owner:
            return Message.new_error(message, "org.freedesktop.DBus.Error.AccessDenied",
                                     "Only NetworkManager may call this agent")
        if message.member == "GetSecrets" and message.signature == "a{sa{sv}}osasu":
            if value(message.body[0], "connection", "uuid") != self.target_uuid:
                # Do not interfere with another application/device's activation.
                return Message.new_error(message, NM + ".SecretAgent.NoSecrets",
                                         "This agent only handles its own activation")
            self.needs_secret = True
            # UserCanceled is terminal. NoSecrets would invite a GUI agent next.
            return Message.new_error(message, NM + ".SecretAgent.UserCanceled",
                                     "Enter credentials in the shell Wi-Fi panel")
        if message.member in ("CancelGetSecrets", "SaveSecrets", "DeleteSecrets"):
            # PSKs use flags=0 (system owned); this agent has no secret storage.
            return Message.new_method_return(message)
        return Message.new_error(message, "org.freedesktop.DBus.Error.UnknownMethod",
                                 "Unsupported secret-agent method")


class Activation:
    def __init__(self, bus):
        self.bus = bus
        self.active_path = None
        self.created_profile_path = None
        self.agent = None
        self.succeeded = False

    async def call(self, path, interface, member, signature="", body=None, destination=NM):
        reply = await asyncio.wait_for(self.bus.call(Message(
            destination=destination, path=path, interface=interface, member=member,
            signature=signature, body=body or [],
        )), timeout=10)
        if reply.message_type == MessageType.ERROR:
            raise DBusError(reply.error_name, reply.body[0] if reply.body else "D-Bus failure")
        return reply.body

    async def prop(self, path, interface, name):
        return (await self.call(path, PROPERTIES, "Get", "ss", [interface, name]))[0].value

    async def access_point(self, device_path, ssid, key_mgmt):
        paths = (await self.call(device_path, NM + ".Device.Wireless", "GetAllAccessPoints"))[0]

        async def candidate(path):
            try:
                props = (await self.call(path, PROPERTIES, "GetAll", "s", [NM + ".AccessPoint"]))[0]
            except DBusError:
                return None  # AP disappeared during the scan.
            if bytes(props["Ssid"].value) != ssid.encode("utf-8"):
                return None
            flags = props["WpaFlags"].value | props["RsnFlags"].value
            supported = ((key_mgmt == "wpa-psk" and flags & 0x100)
                         or (key_mgmt == "sae" and flags & 0x400)
                         or (key_mgmt == "owe" and flags & 0x1800)
                         or (key_mgmt == "open" and not flags and not props["Flags"].value & 1))
            return (props["Strength"].value, path) if supported else None

        candidates = await asyncio.gather(*(candidate(path) for path in paths))
        return max((ap for ap in candidates if ap is not None), default=(0, None))[1]

    async def connect(self, request):
        ssid = request["ssid"]
        device = request["device"]
        psk = request.get("psk")
        profile_uuid = request.get("profile", "")
        key_mgmt = request.get("keyMgmt")
        if (not isinstance(ssid, str) or not 1 <= len(ssid.encode("utf-8")) <= 32
                or not isinstance(device, str) or not device
                or not isinstance(profile_uuid, str)
                or key_mgmt not in (None, "wpa-psk", "sae", "owe", "open")
                or (psk is not None and (not isinstance(psk, str) or not psk
                    or any(ord(c) < 32 or ord(c) == 127 for c in psk)))):
            return {"ok": False, "reason": "invalid-request"}
        if not profile_uuid and key_mgmt is None:
            return {"ok": False, "reason": "advanced"}
        if psk is not None and key_mgmt not in ("wpa-psk", "sae"):
            return {"ok": False, "reason": "advanced"}

        device_path = (await self.call(ROOT, NM, "GetDeviceByIpIface", "s", [device]))[0]
        profile_path = None
        ap_path = "/"
        if profile_uuid:
            profile_path = (await self.call(ROOT + "/Settings", NM + ".Settings",
                                            "GetConnectionByUuid", "s", [profile_uuid]))[0]
            settings = (await self.call(profile_path, NM + ".Settings.Connection", "GetSettings"))[0]
            if (value(settings, "connection", "type") != "802-11-wireless"
                    or bytes(value(settings, "802-11-wireless", "ssid", b"")) != ssid.encode("utf-8")
                    or value(settings, "connection", "interface-name", device) not in ("", device)):
                return {"ok": False, "reason": "profile-changed"}
        else:
            ap_path = await self.access_point(device_path, ssid, key_mgmt)
            if not ap_path:
                return {"ok": False, "reason": "not-found"}
            profile_uuid = str(uuid.uuid4())
            settings = {
                "connection": {
                    "id": Variant("s", ssid), "uuid": Variant("s", profile_uuid),
                    "type": Variant("s", "802-11-wireless"),
                    # Only enable autoconnect after the first successful activation.
                    "autoconnect": Variant("b", False),
                },
                "802-11-wireless": {
                    "ssid": Variant("ay", ssid.encode("utf-8")),
                    "mode": Variant("s", "infrastructure"),
                },
            }
            if key_mgmt != "open":
                settings[SECURITY] = {"key-mgmt": Variant("s", key_mgmt)}

        if psk is not None:
            security = settings.setdefault(SECURITY, {})
            security["psk"] = Variant("s", psk)
            security["psk-flags"] = Variant("u", 0)
            if profile_path:
                # TO_DISK | BLOCK_AUTOCONNECT: avoid an unsolicited activation
                # between updating a saved password and registering our agent.
                await self.call(profile_path, NM + ".Settings.Connection", "Update2",
                                "a{sa{sv}}ua{sv}", [settings, 0x21, {}])

        owner = (await self.call("/org/freedesktop/DBus", "org.freedesktop.DBus",
                                  "GetNameOwner", "s", [NM], "org.freedesktop.DBus"))[0]
        self.agent = ActivationAgent(owner, profile_uuid)
        self.bus.add_message_handler(self.agent.handle)
        await self.call(ROOT + "/AgentManager", NM + ".AgentManager", "RegisterWithCapabilities",
                        "su", ["org.marko_shell.wifi.p" + str(os.getpid()), 0])

        if profile_path:
            self.active_path = (await self.call(ROOT, NM, "ActivateConnection", "ooo",
                                                [profile_path, device_path, "/"]))[0]
        else:
            profile_path, self.active_path = await self.call(ROOT, NM, "AddAndActivateConnection",
                                                             "a{sa{sv}}oo", [settings, device_path, ap_path])
            self.created_profile_path = profile_path

        async with asyncio.timeout(45):
            while True:
                state = await self.prop(self.active_path, NM + ".Connection.Active", "State")
                if state == 2:  # NM_ACTIVE_CONNECTION_STATE_ACTIVATED
                    self.succeeded = True
                    if not request.get("profile"):
                        settings = (await self.call(profile_path, NM + ".Settings.Connection", "GetSettings"))[0]
                        settings["connection"]["autoconnect"] = Variant("b", True)
                        if psk is not None:
                            settings[SECURITY]["psk"] = Variant("s", psk)
                        await self.call(profile_path, NM + ".Settings.Connection", "Update",
                                        "a{sa{sv}}", [settings])
                    return {"ok": True}
                if state == 4:  # NM_ACTIVE_CONNECTION_STATE_DEACTIVATED
                    return {"ok": False, "reason": "secrets" if self.agent.needs_secret else "failed"}
                await asyncio.sleep(0.2)

    async def cleanup(self):
        if self.active_path and not self.succeeded:
            # Cancel only this activation, never a blanket device disconnect.
            # Keep the agent registered until cancellation is acknowledged.
            with contextlib.suppress(DBusError, TimeoutError):
                await self.call(ROOT, NM, "DeactivateConnection", "o", [self.active_path])
                async with asyncio.timeout(3):
                    while await self.prop(self.active_path, NM + ".Connection.Active", "State") != 4:
                        await asyncio.sleep(0.1)
        if self.created_profile_path and not self.succeeded:
            with contextlib.suppress(DBusError, TimeoutError):
                await self.call(self.created_profile_path, NM + ".Settings.Connection", "Delete")


async def run(request, bus=None):
    bus = bus or await MessageBus(bus_type=BusType.SYSTEM).connect()
    activation = Activation(bus)
    task = asyncio.current_task()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGTERM, signal.SIGINT):
        loop.add_signal_handler(sig, task.cancel)
    try:
        return await activation.connect(request)
    except asyncio.CancelledError:
        return {"ok": False, "reason": "cancelled"}
    except TimeoutError:
        return {"ok": False, "reason": "timeout"}
    except DBusError as error:
        if activation.succeeded:
            return {"ok": True, "warning": "autoconnect"}
        reason = "secrets" if activation.agent and activation.agent.needs_secret else "failed"
        if "PermissionDenied" in error.type or "NotAuthorized" in error.type:
            reason = "permission"
        return {"ok": False, "reason": reason}
    finally:
        await activation.cleanup()
        bus.disconnect()


def main():
    try:
        # Bound input before parsing; do not echo malformed requests or exceptions.
        request = json.loads(sys.stdin.read(8193))
        if not isinstance(request, dict):
            raise ValueError("Expected an object")
        result = asyncio.run(run(request))
    except (ValueError, KeyError, TypeError, OSError, EOFError, DBusError):
        result = {"ok": False, "reason": "unavailable"}
    print(json.dumps(result), flush=True)


if __name__ == "__main__":
    main()
